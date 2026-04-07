import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import '../config.dart';
import '../solana/solana_adapter.dart';
import '../ton/ton_adapter.dart';
import '../http/safe_http_client.dart' show SafeHttpClient;
import '../ethereum/ethereum_adapter.dart' show EthereumProvider;
import '../bitcoin/bitcoin_adapter.dart' show BitcoinProvider;
import '../secure_storage/keychain_store.dart' show SeedStore;
import 'wallet_service.dart';

/// Creates the production [WalletService].
///
/// RPC endpoints are injected at compile time via `--dart-define`.
/// See [RpcConfig] for supported providers and usage examples.
///
/// Validation rules (crash-fast in debug, warn in release):
///   • All URLs must be valid `https://` URIs.
///   • Using the unauthenticated Solana public endpoint prints a warning
///     in debug mode — it is rate-limited and unsuitable for production.
WalletService createWalletService(SeedStore seedStore) {
  _validateConfig();

  // Solana — Helius / Alchemy / QuickNode embed the key in the URL:
  //   Helius    : SOLANA_RPC_PRIMARY=https://mainnet.helius-rpc.com/?api-key=YOUR_KEY
  //   Alchemy   : SOLANA_RPC_PRIMARY=https://solana-mainnet.g.alchemy.com/v2/YOUR_KEY
  //   QuickNode : SOLANA_RPC_PRIMARY=https://your-node.solana-mainnet.quiknode.pro/TOKEN/
  // Optional: SOLANA_RPC_BACKUP=https://api.mainnet-beta.solana.com
  final sol = SolanaAdapter(
    endpoint: RpcConfig.solanaRpcPrimary,
    fallbackEndpoints: RpcConfig.solanaFallbackUrls,
  );

  final ton = TonAdapter(
    TonConfig(
      endpoint: RpcConfig.tonRpcUrl,
      apiKey: RpcConfig.tonApiKey.isEmpty ? null : RpcConfig.tonApiKey,
      httpClient: SafeHttpClient(http.Client()),
    ),
  );

  // Ethereum — failover across all configured endpoints.
  // Set --dart-define=DISABLE_ETH=true to skip ALL ETH network calls.
  // Set ETH_FALLBACK_URLS to add backup nodes, e.g.:
  //   --dart-define=ETH_FALLBACK_URLS=https://rpc.ankr.com/eth,https://eth.llamarpc.com
  final eth = RpcConfig.disableEth
      ? () {
          if (kDebugMode) {
            // ignore: avoid_print
            print(
                '[RpcConfig] ETH disabled via --dart-define=DISABLE_ETH=true. '
                'Remove the flag or set ETH_RPC_URL to enable Ethereum.');
          }
          return EthereumProvider.disabled();
        }()
      : EthereumProvider.withFailover(RpcConfig.ethRpcUrls);

  final btc = BitcoinProvider(
    Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    )),
  );

  return WalletService(
      sol: sol, ton: ton, eth: eth, btc: btc, seedStore: seedStore);
}

void _validateConfig() {
  // Validate all RPC URLs at startup before any network call is made.
  final checks = {
    'SOLANA_RPC_PRIMARY': RpcConfig.solanaRpcPrimary,
    'TONCENTER_RPC_URL': RpcConfig.tonRpcUrl,
    'ETH_RPC_URL': RpcConfig.ethRpcUrl,
  };

  for (final url in RpcConfig.solanaFallbackUrls) {
    assert(
      RpcConfig.isValidHttpsUrl(url),
      'Solana fallback URL is not a valid https:// URL: "$url"\n'
      'Check SOLANA_RPC_BACKUP or SOLANA_RPC_FALLBACK_URLS.',
    );
  }

  for (final entry in checks.entries) {
    assert(
      RpcConfig.isValidHttpsUrl(entry.value),
      '${entry.key} is not a valid https:// URL: "${entry.value}"\n'
      'Pass a valid URL via --dart-define=${entry.key}=https://...',
    );
  }

  // Warn (not crash) when using public rate-limited endpoints.
  if (kDebugMode) {
    if (RpcConfig.solanaIsPublicFallback) {
      // ignore: avoid_print
      print(
        '[RpcConfig] WARNING: Using public Solana endpoint (api.mainnet-beta.solana.com).\n'
        'This endpoint is rate-limited and may return 403 in production.\n'
        'Set --dart-define=SOLANA_RPC_PRIMARY=https://mainnet.helius-rpc.com/?api-key=YOUR_KEY',
      );
    }
    if (RpcConfig.ethIsPublicFallback) {
      // ignore: avoid_print
      print(
        '[RpcConfig] WARNING: Using public Ethereum endpoint (eth.llamarpc.com).\n'
        'This endpoint is rate-limited and may return 429 in production.\n'
        'Set --dart-define=ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY',
      );
    }
  }
}
