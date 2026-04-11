import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/network.dart' show AppNetwork;
import '../solana/solana_adapter.dart';
import '../ton/ton_adapter.dart';
import '../http/safe_http_client.dart' show SafeHttpClient;
import '../ethereum/ethereum_adapter.dart' show EthereumProvider;
import '../bitcoin/bitcoin_adapter.dart' show BitcoinProvider;
import '../secure_storage/keychain_store.dart' show SeedStore;
import 'wallet_service.dart';

// ── Testnet public endpoints (no API key required) ─────────────────────────
const _solTestnet = 'https://api.devnet.solana.com';
const _ethTestnet = 'https://rpc.sepolia.org';
const _tonTestnet = 'https://testnet.toncenter.com/api/v2/jsonRPC';
const _btcTestnet = 'https://blockstream.info/testnet/api';

/// Creates the production or testnet [WalletService].
///
/// Pass [network] to switch all chain adapters to their public testnet
/// equivalents without needing any API key.
///
/// Validation rules apply to mainnet only (testnet uses hardcoded public URLs).
WalletService createWalletService(
  SeedStore seedStore, {
  AppNetwork network = AppNetwork.mainnet,
}) {
  if (network == AppNetwork.mainnet) _validateConfig();

  final isTestnet = network == AppNetwork.testnet;

  // Solana — Devnet on testnet, mainnet RPC (--dart-define) on mainnet.
  final sol = SolanaAdapter(
    endpoint: isTestnet ? _solTestnet : RpcConfig.solanaRpcPrimary,
    fallbackEndpoints: isTestnet ? const [] : RpcConfig.solanaFallbackUrls,
  );

  // TON — testnet.toncenter.com on testnet; authenticated mainnet otherwise.
  final ton = TonAdapter(
    TonConfig(
      endpoint: isTestnet ? _tonTestnet : RpcConfig.tonRpcUrl,
      // API key only applies to mainnet (testnet endpoint is unauthenticated).
      apiKey: isTestnet
          ? null
          : (RpcConfig.tonApiKey.isEmpty ? null : RpcConfig.tonApiKey),
      httpClient: SafeHttpClient(http.Client()),
    ),
  );

  // Ethereum — Sepolia testnet or mainnet failover.
  // DISABLE_ETH skips ETH entirely (useful for debugging other chains).
  final eth = RpcConfig.disableEth
      ? () {
          if (kDebugMode) {
            // ignore: avoid_print
            print(
                '[RpcConfig] ETH disabled via --dart-define=DISABLE_ETH=true.');
          }
          return EthereumProvider.disabled();
        }()
      : EthereumProvider.withFailover(
          isTestnet ? [_ethTestnet] : RpcConfig.ethRpcUrls,
        );

  // Bitcoin — blockstream.info testnet3 or mainnet API.
  final btc = BitcoinProvider(
    Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    )),
    baseUrl: isTestnet ? _btcTestnet : 'https://blockstream.info/api',
  );

  return WalletService(
    sol: sol,
    ton: ton,
    eth: eth,
    btc: btc,
    seedStore: seedStore,
    ethereumChainId: isTestnet ? 11155111 : 1,
    bitcoinNetwork: isTestnet ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet,
  );
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
