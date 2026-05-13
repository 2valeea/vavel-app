# Agents

## Cursor Cloud specific instructions

### Project structure

- **Flutter mobile app** at `vavel_app/` — non-custodial crypto wallet (Solana, Ethereum, TON)
- **Stripe server** at `vavel_app/stripe_server/` — Node.js/Express/TypeScript backend for in-app purchase checkout

### Prerequisites

Flutter SDK must be on PATH: `export PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"`.
Node.js (v22+) is pre-installed.

### Commands

| Task | Command | Working directory |
|------|---------|-------------------|
| Install Flutter deps | `flutter pub get` | `vavel_app/` |
| Install Stripe deps | `npm install` | `vavel_app/stripe_server/` |
| Lint (Flutter) | `flutter analyze --no-fatal-infos` | `vavel_app/` |
| Tests (Flutter) | `flutter test` | `vavel_app/` |
| TypeScript check | `npx tsc --noEmit` | `vavel_app/stripe_server/` |
| Run Flutter web | `flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0` | `vavel_app/` |
| Run Stripe server (dev) | `npm run dev` | `vavel_app/stripe_server/` |
| Build Stripe server | `npm run build` | `vavel_app/stripe_server/` |

### Environment files

- `vavel_app/.env` — requires `HELIUS_API_KEY` for Solana RPC (app works without it but blockchain calls fail)
- `vavel_app/stripe_server/.env` — requires `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `PUBLIC_BASE_URL`. Copy from `.env.example`.

### Gotchas

- The Flutter app has a paywall after wallet creation; to access the main wallet dashboard in testing, you need valid Stripe credentials or must bypass the paywall logic.
- Flutter web mode is the only target available in headless Linux VMs (no Android emulator or iOS simulator). Use `flutter run -d web-server` for web testing.
- The Stripe server exits immediately if `STRIPE_SECRET_KEY` is not set in `.env`. Use placeholder values (`sk_test_placeholder`) for startup verification only.
- CI workflow (`.github/workflows/flutter_ci.yml`) runs: `flutter pub get` → `flutter analyze --no-fatal-infos` → `flutter test`.
