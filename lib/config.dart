/// Compile-time configuration injected via `--dart-define`.
///
/// Never commit real keys to source control. Inject through your CI pipeline
/// or a local build script.
///
/// ── Solana providers ────────────────────────────────────────────────────────
///
/// Alchemy (key embedded in URL path):
///   flutter run \
///     --dart-define=SOLANA_RPC_PRIMARY=https://solana-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
///
/// Helius (key embedded as query param):
///   flutter run \
///     --dart-define=SOLANA_RPC_PRIMARY=https://mainnet.helius-rpc.com/?api-key=YOUR_KEY
///
/// QuickNode (token embedded in URL path):
///   flutter run \
///     --dart-define=SOLANA_RPC_PRIMARY=https://your-endpoint.solana-mainnet.quiknode.pro/YOUR_TOKEN/
///
/// ── Other networks ───────────────────────────────────────────────────────────
///
///   flutter run \
///     --dart-define=TONCENTER_API_KEY=YOUR_TONCENTER_KEY \
///     --dart-define=ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
///
/// GitHub Actions:
///   flutter build appbundle \
///     --dart-define=SOLANA_RPC_PRIMARY=${{ secrets.SOLANA_RPC_PRIMARY }} \
///     --dart-define=TONCENTER_API_KEY=${{ secrets.TONCENTER_API_KEY }} \
///     --dart-define=ETH_RPC_URL=${{ secrets.ETH_RPC_URL }}
abstract final class RpcConfig {
  // ── Solana ────────────────────────────────────────────────────────────────

  /// Primary Solana JSON-RPC endpoint (authenticated).
  ///
  /// All three major providers embed the key inside the URL:
  ///   • Helius   : SOLANA_RPC_PRIMARY=https://mainnet.helius-rpc.com/?api-key=YOUR_KEY
  ///   • Alchemy  : SOLANA_RPC_PRIMARY=https://solana-mainnet.g.alchemy.com/v2/YOUR_KEY
  ///   • QuickNode: SOLANA_RPC_PRIMARY=https://your-node.solana-mainnet.quiknode.pro/TOKEN/
  static const solanaRpcPrimary = String.fromEnvironment(
    'SOLANA_RPC_PRIMARY',
    defaultValue: 'https://api.mainnet-beta.solana.com',
  );

  /// Optional backup Solana endpoint — used before the generic public fallbacks.
  ///
  ///   --dart-define=SOLANA_RPC_BACKUP=https://api.mainnet-beta.solana.com
  ///
  /// Leave unset (empty) to rely solely on [solanaRpcPrimary] and the
  /// built-in public fallbacks in [SolanaAdapter].
  static const solanaRpcBackup = String.fromEnvironment('SOLANA_RPC_BACKUP');

  /// Optional comma-separated list of extra Solana fallback endpoints.
  ///
  /// Example:
  ///   --dart-define=SOLANA_RPC_FALLBACK_URLS=https://api.mainnet-beta.solana.com,https://rpc.ankr.com/solana
  ///
  /// Never use demo/unauthenticated provider demo keys here (e.g. /v2/demo).
  static const _solanaFallbackRaw =
      String.fromEnvironment('SOLANA_RPC_FALLBACK_URLS');

  /// Ordered fallback list passed to [SolanaAdapter]:
  ///   1. [solanaRpcBackup] (if set via SOLANA_RPC_BACKUP)
  ///   2. Entries from SOLANA_RPC_FALLBACK_URLS (CSV, in order)
  ///   3. Public mainnet as last resort
  ///
  /// Deduplicates against [solanaRpcPrimary] and earlier entries.
  static List<String> get solanaFallbackUrls {
    const publicFallback = 'https://api.mainnet-beta.solana.com';
    final seen = <String>{solanaRpcPrimary};
    final result = <String>[];

    if (solanaRpcBackup.isNotEmpty && seen.add(solanaRpcBackup)) {
      result.add(solanaRpcBackup);
    }
    for (final url in _solanaFallbackRaw.split(',').map((s) => s.trim())) {
      if (url.isNotEmpty && seen.add(url)) result.add(url);
    }
    if (seen.add(publicFallback)) result.add(publicFallback);
    return result;
  }

  // ── TON ───────────────────────────────────────────────────────────────────

  static const tonRpcUrl = String.fromEnvironment(
    'TONCENTER_RPC_URL',
    defaultValue: 'https://toncenter.com/api/v2/jsonRPC',
  );

  static const tonApiKey = String.fromEnvironment('TONCENTER_API_KEY');

  // ── Ethereum ──────────────────────────────────────────────────────────────

  /// Primary Ethereum JSON-RPC endpoint.
  ///
  /// Recommended providers (key embedded in URL):
  ///   • Alchemy  : ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
  ///   • Infura   : ETH_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
  ///   • QuickNode: ETH_RPC_URL=https://YOUR_NODE.quiknode.pro/YOUR_TOKEN/
  static const ethRpcUrl = String.fromEnvironment(
    'ETH_RPC_URL',
    defaultValue: 'https://eth.llamarpc.com',
  );

  /// Comma-separated list of fallback Ethereum endpoints used by [EthRpcFailover].
  ///
  ///   --dart-define=ETH_FALLBACK_URLS=https://rpc.ankr.com/eth,https://eth.llamarpc.com
  ///
  /// When empty the failover list contains only [ethRpcUrl] (single-endpoint mode).
  static const _ethFallbackRaw = String.fromEnvironment('ETH_FALLBACK_URLS');

  /// Ordered list: primary first, then any [_ethFallbackRaw] entries.
  /// Always non-empty.
  static List<String> get ethRpcUrls {
    final extras = _ethFallbackRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != ethRpcUrl)
        .toList();
    return [ethRpcUrl, ...extras];
  }

  /// `true` when using the public llamarpc endpoint (no key, rate-limited).
  static bool get ethIsPublicFallback =>
      ethRpcUrl == 'https://eth.llamarpc.com';

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns `true` if [url] starts with `https://` and is non-empty.
  static bool isValidHttpsUrl(String url) =>
      url.isNotEmpty && Uri.tryParse(url)?.isScheme('https') == true;

  /// `true` when the unauthenticated public Solana endpoint is in use.
  /// This endpoint is rate-limited and should not be used in production.
  static bool get solanaIsPublicFallback =>
      solanaRpcPrimary == 'https://api.mainnet-beta.solana.com';

  // ── Debug flags ───────────────────────────────────────────────────────────

  /// Set `--dart-define=DISABLE_ETH=true` to skip all Ethereum/ERC-20 calls.
  /// Useful when testing Solana/TON/BTC without an Ethereum RPC key.
  static const disableEth =
      bool.fromEnvironment('DISABLE_ETH', defaultValue: false);

  // ── WalletConnect (Reown) ────────────────────────────────────────────────

  /// WalletConnect/Reown Cloud project id used by `reown_walletkit`.
  ///
  /// Example:
  ///   --dart-define=WC_PROJECT_ID=your_reown_project_id
  static const walletConnectProjectId =
      String.fromEnvironment('WC_PROJECT_ID', defaultValue: '');

  /// `true` when [walletConnectProjectId] is non-empty and matches a typical Reown ID shape.
  ///
  /// Very short or non-alphanumeric values are treated as misconfiguration so the app
  /// can show a clear setup message instead of failing inside the WalletConnect SDK.
  static bool get isWalletConnectProjectIdConfigured {
    final p = walletConnectProjectId.trim();
    if (p.length < 10 || p.length > 80) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(p);
  }

  // ── VAVEL (ERC-20 on Ethereum) ───────────────────────────────────────────

  /// Mainnet ERC-20 contract for the VAVEL token (checksummed `0x…` address).
  ///
  /// Example:
  ///   --dart-define=VAVEL_TOKEN_CONTRACT=0xYourContractAddress
  ///
  /// When unset or invalid, VAVEL balance reads as zero and transfers are disabled.
  static const vavelTokenContract =
      String.fromEnvironment('VAVEL_TOKEN_CONTRACT', defaultValue: '');

  /// `true` when [vavelTokenContract] looks like a valid 20-byte hex address.
  static bool get vavelTokenConfigured {
    final a = vavelTokenContract.trim();
    return a.startsWith('0x') && a.length == 42;
  }

  // ── Push (FCM token → your backend) ─────────────────────────────────────

  /// Full HTTPS URL for registering the device FCM token (POST JSON body).
  ///
  /// Example:
  ///   --dart-define=PUSH_REGISTER_URL=https://api.vavel.app/v1/devices/fcm
  ///
  /// Body: `{ "walletAddress": "0x…", "token": "…", "platform": "android" }`
  /// When empty, the app still receives FCM locally but does not call a server.
  static const pushRegisterUrl =
      String.fromEnvironment('PUSH_REGISTER_URL', defaultValue: '');

  /// Optional `Authorization: Bearer …` for [pushRegisterUrl].
  static const pushRegisterBearer =
      String.fromEnvironment('PUSH_REGISTER_BEARER', defaultValue: '');
}
