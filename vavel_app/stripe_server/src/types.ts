import type Stripe from 'stripe';

/** JSON error body for our API. */
export type ApiErrorResponse = { error: string };

/** `POST /create-checkout-session` success body. */
export type CreateCheckoutSessionResponse = {
  url: string | null;
  id: string;
};

/**
 * `GET /verify-checkout-session` success body.
 * `source` explains whether `paid` came from live Stripe state or webhook ledger (async edge cases).
 */
export type VerifyCheckoutSessionResponse = {
  paid: boolean;
  status: Stripe.Checkout.Session.PaymentStatus | string;
  source: 'stripe_session' | 'webhook_ledger';
};

/** `GET /config` — publishable key only (safe for browsers / apps). */
export type PublicConfigResponse = {
  publishableKey: string;
};

/** `POST /webhook` acknowledgment (Stripe ignores body; we still return JSON). */
export type WebhookAckResponse = { received: true };

/** In-memory fulfillment record (replace with your DB). */
export type FulfillmentRecord = {
  sessionId: string;
  fulfilledAt: string;
  customerEmail: string | null;
};

/** `GET /fulfillment-status?session_id=` */
export type FulfillmentStatusResponse = {
  fulfilled: boolean;
  record: FulfillmentRecord | null;
};

/** `POST /create-payment-intent` success body. */
export type CreatePaymentIntentResponse = {
  clientSecret: string | null;
};
