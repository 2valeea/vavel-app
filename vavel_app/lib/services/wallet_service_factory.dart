import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/network.dart' show AppNetwork;
import '../solana/solana_adapter.dart';
import '../ton/ton_adapter.dart';
import '../ethereum/ethereum_adapter.dart';
import '../http/safe_http_client.dart' show SafeHttpClient;
import '../secure_storage/keychain_store.dart' show SeedStore;
import 'wallet_service.dart';

const _solTestnet = 'https://api.devnet.solana.com';
const _tonTestnet = 'https://testnet.toncenter.com/api/v2/jsonRPC';
const _ethTestnet = 'https://rpc.sepolia.org';

WalletService createWalletService(
  SeedStore seedStore, {
  AppNetwork network = AppNetwork.mainnet,
}) {
  if (network == AppNetwork.mainnet) _validateConfig();

  final isTestnet = network == AppNetwork.testnet;

  final sol = SolanaAdapter(
    endpoint: isTestnet ? _solTestnet : RpcConfig.solanaRpcPrimary,
    fallbackEndpoints: isTestnet ? const [] : RpcConfig.solanaFallbackUrls,
  );

  final ton = TonAdapter(
    TonConfig(
      endpoint: isTestnet ? _tonTestnet : RpcConfig.tonRpcUrl,
      apiKey: isTestnet
          ? null
          : (RpcConfig.tonApiKey.isEmpty ? null : RpcConfig.tonApiKey),
      httpClient: SafeHttpClient(http.Client()),
    ),
  );

  final eth = RpcConfig.disableEth
      ? EthereumProvider.disabled()
      : EthereumProvider.withFailover(
          isTestnet ? [_ethTestnet] : RpcConfig.ethRpcUrls,
        );

  if (kDebugMode && RpcConfig.disableEth) {
    // ignore: avoid_print
    print('[RpcConfig] ETH disabled via --dart-define=DISABLE_ETH=true.');
  }

  return WalletService(
    sol: sol,
    ton: ton,
    eth: eth,
    seedStore: seedStore,
    ethereumChainId: isTestnet ? 11155111 : 1,
  );
}

void _validateConfig() {
  final checks = <String, String>{
    'SOLANA_RPC_PRIMARY': RpcConfig.solanaRpcPrimary,
    'TONCENTER_RPC_URL': RpcConfig.tonRpcUrl,
  };
  if (!RpcConfig.disableEth) {
    checks['ETH_RPC_URL'] = RpcConfig.ethRpcUrl;
  }

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

  if (kDebugMode && RpcConfig.solanaIsPublicFallback) {
    // ignore: avoid_print
    print(
      '[RpcConfig] WARNING: Using public Solana endpoint (api.mainnet-beta.solana.com).\n'
      'Set --dart-define=SOLANA_RPC_PRIMARY=https://mainnet.helius-rpc.com/?api-key=YOUR_KEY',
    );
  }
  if (kDebugMode && !RpcConfig.disableEth && RpcConfig.ethIsPublicFallback) {
    // ignore: avoid_print
    print(
      '[RpcConfig] WARNING: Using public Ethereum endpoint (eth.llamarpc.com).\n'
      'Set --dart-define=ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY',
    );
  }
}
