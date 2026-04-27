/// Stripe Checkout & backend configuration (`--dart-define`).
///
/// **Secret key** belongs only on the server (`STRIPE_SECRET_KEY` in `.env`).
/// **Publishable key** (`pk_…`) may be compiled into the app or loaded from `GET /config` on your backend.
abstract final class StripeConfig {
  /// Base URL of your Node server (no trailing slash), e.g. `https://api.example.com` or `http://10.0.2.2:4242`.
  static const backendBaseUrl = String.fromEnvironment(
    'STRIPE_BACKEND_URL',
    defaultValue: 'http://127.0.0.1:4242',
  );

  /// Publishable key only (`pk_live_…` / `pk_test_…`). Never put `sk_…` in the app.
  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// One-time access price in the **smallest currency unit** (e.g. 1000 = 10.00 EUR).
  static const unlockAmountMinor = int.fromEnvironment(
    'STRIPE_UNLOCK_AMOUNT_MINOR',
    defaultValue: 1000,
  );

  /// ISO currency code for Checkout (default **eur** — 10.00 EUR with default minor amount).
  static const unlockCurrency = String.fromEnvironment(
    'STRIPE_UNLOCK_CURRENCY',
    defaultValue: 'eur',
  );

  static Uri get createCheckoutSessionUri =>
      Uri.parse('${backendBaseUrl.trim()}/create-checkout-session');

  static Uri verifyCheckoutSessionUri(String sessionId) => Uri.parse(
        '${backendBaseUrl.trim()}/verify-checkout-session',
      ).replace(queryParameters: {'session_id': sessionId});

  /// Human-readable total for UI (two decimals; OK for EUR/USD).
  static String get formattedUnlockTotal =>
      '${(unlockAmountMinor / 100.0).toStringAsFixed(2)} ${unlockCurrency.toUpperCase()}';
}
