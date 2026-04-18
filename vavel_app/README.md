# VAVEL Wallet (Vavel Wallet)

**VAVEL Wallet** is the official mobile app for holding and sending **VAVEL** and other supported assets (Ethereum, Solana, TON, Bitcoin). It is published on Google Play.

## Google Play

- **Listing:** [VAVEL Wallet on Google Play](https://play.google.com/store/apps/details?id=com.vavel.vavel_wallet)
- **Application ID:** `com.vavel.vavel_wallet`

Use the same public name, short description, and graphics as in the Play Console so store and GitHub stay aligned.

## Source repository

- **GitHub:** [github.com/2valeea/vavel-app](https://github.com/2valeea/vavel-app)

```bash
git clone https://github.com/2valeea/vavel-app.git
cd vavel-app/vavel_app
flutter pub get
flutter run
```

## VAVEL token (metadata)

| Field | Value |
|--------|--------|
| **Symbol** | VAVEL |
| **Decimals** | 18 (EVM ERC-20) |
| **Network** | Ethereum mainnet (EVM) |
| **Contract** | Set at build time via `--dart-define=VAVEL_TOKEN_CONTRACT=0x…` (see `lib/config.dart`). Not hard-coded in this repo. |
| **In-app service fee** | A separate on-chain transfer of **1 VAVEL** to the operator address shown in the app and in the Terms of Service before the user’s main send (EVM sends). |

**Canonical logo (for lists / verification forms):**  
`https://raw.githubusercontent.com/2valeea/vavel-app/main/vavel_app/assets/images/VAVEL.jpeg`

**Project site (WalletConnect metadata):** [https://vavel.app](https://vavel.app)

## Verification (wallets & explorers)

- **Tonkeeper / `tonkeeper/ton-assets`:** That registry is for **TON jettons** (TON blockchain). If VAVEL exists **only** as an **ERC-20 on Ethereum**, use Ethereum-focused token lists (e.g. token lists used by explorers and DEX aggregators) rather than Tonkeeper jetton PRs. If you also deploy a **VAVEL jetton on TON**, add a YAML under `jettons/` in [tonkeeper/ton-assets](https://github.com/tonkeeper/ton-assets) per [Tonkeeper’s token verification guide](https://tonkeeper.helpscoutdocs.com/article/127-tokennftverification).

## Features

- Multi-asset balances and send flows  
- WalletConnect (Ethereum)  
- Secure storage and PIN  

## Project layout

Flutter app code lives under `vavel_app/` (this directory).

## Contributing

Fork the repository and open a pull request. Keep store copy and this README in sync when you change branding or fee disclosure.

## License

If the repository includes a `LICENSE` file at the root, refer to that file for terms.
