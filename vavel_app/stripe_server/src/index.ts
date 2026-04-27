import 'dotenv/config';
import express, { type Request, type Response, type NextFunction } from 'express';
import Stripe from 'stripe';

import type {
  ApiErrorResponse,
  CreateCheckoutSessionResponse,
  CreatePaymentIntentResponse,
  FulfillmentStatusResponse,
  PublicConfigResponse,
  VerifyCheckoutSessionResponse,
  WebhookAckResponse,
} from './types';
import { getFulfillment, isWebhookFulfilled, markFulfilled } from './fulfillmentLedger';
import { canceledPageHtml, successPageHtml } from './htmlPages';

const secret = process.env.STRIPE_SECRET_KEY;
if (!secret) {
  console.error('Missing STRIPE_SECRET_KEY in .env');
  process.exit(1);
}

const stripe = new Stripe(secret);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
const publishableKey = process.env.STRIPE_PUBLISHABLE_KEY || '';
const publicBase = (process.env.PUBLIC_BASE_URL || '').replace(/\/$/, '');

const app = express();

function corsMiddleware(req: Request, res: Response, next: NextFunction): void {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Stripe-Signature');
  if (req.method === 'OPTIONS') {
    res.sendStatus(204);
    return;
  }
  next();
}

app.use(corsMiddleware);

app.post(
  '/webhook',
  express.raw({ type: 'application/json' }),
  (req: Request, res: Response) => {
    void handleWebhook(req, res);
  },
);

app.use(express.json());

app.get('/config', (_req: Request, res: Response) => {
  const body: PublicConfigResponse = { publishableKey };
  res.json(body);
});

app.get('/success', (req: Request, res: Response) => {
  const sessionId =
    typeof req.query.session_id === 'string' ? req.query.session_id : undefined;
  res.type('html').send(successPageHtml(sessionId));
});

app.get('/canceled', (_req: Request, res: Response) => {
  res.type('html').send(canceledPageHtml());
});

/**
 * POST /create-checkout-session
 * Body: { amount?, currency?, successUrl?, cancelUrl?, productName?, metadata? }
 */
app.post('/create-checkout-session', async (req: Request, res: Response) => {
  try {
    const unitAmount =
      Number(req.body?.amount) ||
      Number(process.env.CHECKOUT_AMOUNT_MINOR) ||
      1000;
    const currency = (req.body?.currency || process.env.CHECKOUT_CURRENCY || 'eur')
      .toString()
      .toLowerCase();

    let successUrl =
      (typeof req.body?.successUrl === 'string' && req.body.successUrl.trim()) ||
      process.env.CHECKOUT_SUCCESS_URL?.trim() ||
      '';
    let cancelUrl =
      (typeof req.body?.cancelUrl === 'string' && req.body.cancelUrl.trim()) ||
      process.env.CHECKOUT_CANCEL_URL?.trim() ||
      '';

    if ((!successUrl || !cancelUrl) && publicBase) {
      successUrl = `${publicBase}/success?session_id={CHECKOUT_SESSION_ID}`;
      cancelUrl = `${publicBase}/canceled`;
    }

    if (!successUrl || !cancelUrl) {
      const err: ApiErrorResponse = {
        error:
          'Configure PUBLIC_BASE_URL (e.g. https://api.example.com) for /success and /canceled redirects, ' +
          'or pass successUrl and cancelUrl in the JSON body (success URL must include {CHECKOUT_SESSION_ID} for Stripe).',
      };
      return res.status(400).json(err);
    }

    const productName =
      (typeof req.body?.productName === 'string' && req.body.productName) ||
      'Wallet Vaval access';

    const rawMeta = req.body?.metadata;
    const metadata =
      rawMeta != null && typeof rawMeta === 'object' && !Array.isArray(rawMeta)
        ? (rawMeta as Record<string, string>)
        : undefined;

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency,
            unit_amount: unitAmount,
            product_data: { name: productName },
          },
        },
      ],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata,
    });

    const body: CreateCheckoutSessionResponse = { url: session.url, id: session.id };
    res.json(body);
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : String(e);
    console.error(e);
    const err: ApiErrorResponse = { error: message };
    res.status(500).json(err);
  }
});

app.get('/verify-checkout-session', async (req: Request, res: Response) => {
  try {
    const id = req.query.session_id;
    if (!id || typeof id !== 'string') {
      const err: ApiErrorResponse = { error: 'missing session_id' };
      return res.status(400).json(err);
    }

    const session: Stripe.Checkout.Session = await stripe.checkout.sessions.retrieve(id);

    let paid =
      session.payment_status === 'paid' || session.payment_status === 'no_payment_required';
    let source: VerifyCheckoutSessionResponse['source'] = 'stripe_session';

    if (!paid && isWebhookFulfilled(id)) {
      paid = true;
      source = 'webhook_ledger';
    }

    const body: VerifyCheckoutSessionResponse = {
      paid,
      status: session.payment_status,
      source,
    };
    res.json(body);
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : String(e);
    console.error(e);
    const err: ApiErrorResponse = { error: message };
    res.status(500).json(err);
  }
});

/** Optional: inspect server-side fulfillment (webhook) for a session. */
app.get('/fulfillment-status', (req: Request, res: Response) => {
  const id = req.query.session_id;
  if (!id || typeof id !== 'string') {
    const err: ApiErrorResponse = { error: 'missing session_id' };
    return res.status(400).json(err);
  }
  const rec = getFulfillment(id);
  const body: FulfillmentStatusResponse = { fulfilled: !!rec, record: rec ?? null };
  res.json(body);
});

app.post('/create-payment-intent', async (req: Request, res: Response) => {
  try {
    const amount = Number(req.body?.amount) || 1000;
    const currency = (req.body?.currency || 'eur').toString().toLowerCase();
    const pi = await stripe.paymentIntents.create({
      amount,
      currency,
      automatic_payment_methods: { enabled: true },
    });
    const body: CreatePaymentIntentResponse = { clientSecret: pi.client_secret };
    res.json(body);
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : String(e);
    console.error(e);
    const err: ApiErrorResponse = { error: message };
    res.status(500).json(err);
  }
});

async function handleWebhook(req: Request, res: Response): Promise<void> {
  if (!webhookSecret) {
    const err: ApiErrorResponse = {
      error:
        'STRIPE_WEBHOOK_SECRET is not set. Add it from Stripe Dashboard → Webhooks → signing secret, ' +
        'or use `stripe listen --forward-to localhost:PORT/webhook` for local testing.',
    };
    res.status(503).json(err);
    return;
  }

  const sig = req.headers['stripe-signature'];
  if (!sig || typeof sig !== 'string') {
    const err: ApiErrorResponse = { error: 'Missing Stripe-Signature header' };
    res.status(400).json(err);
    return;
  }

  let event: Stripe.Event;
  try {
    const buf = req.body as Buffer;
    event = stripe.webhooks.constructEvent(buf, sig, webhookSecret);
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : String(e);
    console.error('Webhook signature verification failed:', message);
    const err: ApiErrorResponse = { error: message };
    res.status(400).json(err);
    return;
  }

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      recordFulfillment(session);
      break;
    }
    case 'checkout.session.async_payment_succeeded': {
      const session = event.data.object as Stripe.Checkout.Session;
      recordFulfillment(session);
      break;
    }
    case 'checkout.session.async_payment_failed': {
      const session = event.data.object as Stripe.Checkout.Session;
      console.warn('[Stripe webhook] async_payment_failed', session.id);
      break;
    }
    default:
      break;
  }

  const ack: WebhookAckResponse = { received: true };
  res.json(ack);
}

function recordFulfillment(session: Stripe.Checkout.Session): void {
  if (!session.id) return;
  const email = session.customer_details?.email ?? null;
  markFulfilled({
    sessionId: session.id,
    fulfilledAt: new Date().toISOString(),
    customerEmail: email,
  });
  console.log('[Stripe webhook] Recorded fulfillment for Checkout Session', session.id);
}

const port = Number(process.env.PORT) || 4242;
app.listen(port, '0.0.0.0', () => {
  console.log(`Stripe server http://0.0.0.0:${port}`);
  console.log('  POST /create-checkout-session');
  console.log('  GET  /verify-checkout-session?session_id=...');
  console.log('  POST /webhook');
  console.log('  GET  /success   GET /canceled');
  console.log('  GET  /config (publishable key only)');
  if (!publicBase) {
    console.warn('Warning: PUBLIC_BASE_URL is empty — Checkout needs absolute /success and /canceled URLs.');
  }
  if (!webhookSecret) {
    console.warn('Warning: STRIPE_WEBHOOK_SECRET is empty — webhooks disabled until configured.');
  }
});
