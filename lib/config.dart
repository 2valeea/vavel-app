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
}
