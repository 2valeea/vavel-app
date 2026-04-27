# Stripe server (Wallet Vaval) — TypeScript

Creates **Stripe Checkout** sessions, hosts **`/success`** and **`/canceled`** return pages, verifies sessions for the app, and records **fulfillment via webhooks** (replace the in-memory ledger with your database).

## Security

- **`STRIPE_SECRET_KEY`** — server only (`.env`, never committed).
- **`STRIPE_PUBLISHABLE_KEY`** — safe for clients; exposed at **`GET /config`** and optionally mirrored in the Flutter app via `--dart-define=STRIPE_PUBLISHABLE_KEY=...`.
- **`STRIPE_WEBHOOK_SECRET`** — verify webhook signatures (`whsec_…`).

## Setup

1. `cd stripe_server`
2. `cp .env.example .env` and set **`STRIPE_SECRET_KEY`**, **`STRIPE_PUBLISHABLE_KEY`**, **`PUBLIC_BASE_URL`** (HTTPS in production), and **`STRIPE_WEBHOOK_SECRET`** after you create the webhook endpoint.
3. `npm install`
4. `npm run build`
5. `npm start` (or `npm run dev` while developing)

## Stripe Dashboard

1. **Webhooks** → Add endpoint `https://<your-host>/webhook`  
   Subscribe at minimum to: **`checkout.session.completed`**, **`checkout.session.async_payment_succeeded`**, **`checkout.session.async_payment_failed`** (optional but useful).
2. Copy the **signing secret** into `STRIPE_WEBHOOK_SECRET`.
3. Checkout **success/cancel** URLs are generated from **`PUBLIC_BASE_URL`** (`/success` and `/canceled`). Ensure that origin matches what you deploy.

### Local webhook testing

```bash
stripe listen --forward-to localhost:4242/webhook
```

Use the CLI signing secret as `STRIPE_WEBHOOK_SECRET` while testing.

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/create-checkout-session` | Create Checkout Session; response `{ url, id }`. |
| `GET` | `/verify-checkout-session?session_id=` | For the app after return; `{ paid, status, source }`. |
| `POST` | `/webhook` | Stripe events; records fulfillment (extend to grant DB access). |
| `GET` | `/success` | Stripe redirect after payment; offers deep link back to the app. |
| `GET` | `/canceled` | Stripe redirect if the user cancels Checkout. |
| `GET` | `/config` | `{ publishableKey }` — no secrets. |
| `GET` | `/fulfillment-status?session_id=` | Debug: whether webhook recorded fulfillment. |
| `POST` | `/create-payment-intent` | Legacy helper. |

### Checkout URLs

If the client does not send `successUrl` / `cancelUrl`, the server uses:

- `success` → `{PUBLIC_BASE_URL}/success?session_id={CHECKOUT_SESSION_ID}`
- `cancel` → `{PUBLIC_BASE_URL}/canceled`

Override with JSON body or `CHECKOUT_SUCCESS_URL` / `CHECKOUT_CANCEL_URL` in `.env` if needed.

## Flutter (`--dart-define`)

- **`STRIPE_BACKEND_URL`** — same origin as `PUBLIC_BASE_URL` in typical setups (no trailing slash).
- **`STRIPE_PUBLISHABLE_KEY`** — optional mirror of the public key (must not be the secret key).
- **`STRIPE_UNLOCK_AMOUNT_MINOR`**, **`STRIPE_UNLOCK_CURRENCY`** — must match what you pass to `/create-checkout-session`.

Physical devices cannot use `http://127.0.0.1` for Stripe return URLs; use a tunnel (e.g. ngrok) and set **`PUBLIC_BASE_URL`** to the HTTPS tunnel URL.
