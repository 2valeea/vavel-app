import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bitcoin/bitcoin_adapter.dart' show BitcoinProvider;
import '../config.dart' show RpcConfig;
import '../ethereum/ethereum_adapter.dart' show EthereumProvider;
import '../models/asset.dart' show AssetBalance;
import '../models/ethereum_gas_fees.dart'
    show EthereumMaxFeeArgs, EthereumNetworkGasFees;
import '../models/fee_estimate.dart' show FeeEstimate;
import '../services/portfolio_service.dart';
import '../services/fee_service.dart';
import 'wallet_provider.dart';
import 'price_provider.dart' show priceProviderInstance;

// ── Shared Dio instance ───────────────────────────────────────────────────

/// A single [Dio] instance shared across all network providers.
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    // Some public APIs (rates, RPC) reject requests without a UA.
    headers: const {
      'User-Agent': 'VavelWallet/1.0 (Flutter; https://vavel.io)',
      'Accept': 'application/json',
    },
  ));
});

// ── Network providers ─────────────────────────────────────────────────────

final btcNetworkProvider = Provider<BitcoinProvider>((ref) {
  return BitcoinProvider(ref.read(dioProvider));
});

final ethNetworkProvider = Provider<EthereumProvider>((ref) {
  return EthereumProvider.withFailover(RpcConfig.ethRpcUrls);
});

// ── Portfolio service ─────────────────────────────────────────────────────

final portfolioServiceProvider = Provider<PortfolioService>((ref) {
  return PortfolioService(
    btcProvider: ref.read(btcNetworkProvider),
    ethProvider: ref.read(ethNetworkProvider),
  );
});

// ── Fee service ───────────────────────────────────────────────────────────

final feeServiceProvider = Provider<FeeService>((ref) {
  return FeeService(
    btc: ref.read(btcNetworkProvider),
    eth: ref.read(ethNetworkProvider),
    prices: ref.read(priceProviderInstance),
  );
});

// ── Balances ──────────────────────────────────────────────────────────────

/// Fetches BTC + ETH/ERC-20 balances using [PortfolioService].
///
/// Addresses are derived automatically from the stored mnemonic via
/// [walletAddressesProvider]; no hardcoded values needed.
final portfolioBalancesProvider =
    FutureProvider<List<AssetBalance>>((ref) async {
  final portfolio = ref.watch(portfolioServiceProvider);
  final addresses = await ref.watch(walletAddressesProvider.future);
  return portfolio.getBalances(
    btcAddress: addresses.bitcoin,
    ethAddress: addresses.ethereum,
  );
});

// ── Fee estimation ─────────────────────────────────────────────────────────

/// Standard gas limits per transaction type. Pass as the [gasLimit] argument
/// to [ethFeeProvider].
const kEthTransferGasLimit = 21000;
const kErc20TransferGasLimit = 65000;

/// Estimates the Ethereum network fee for [gasLimit] gas units.
///
/// Throws [FeeEstimationException] on failure — use [AsyncValue.error] in UI
/// to display [FeeEstimationException.userMessage].
final ethFeeProvider = FutureProvider.family<FeeEstimate, int>((ref, gasLimit) {
  return ref
      .read(feeServiceProvider)
      .estimateEthereumFeeUsd(gasLimit: gasLimit);
});

/// Live slow / standard / fast gas (or legacy) for send UI.
final ethereumNetworkGasFeesProvider =
    FutureProvider<EthereumNetworkGasFees>((ref) async {
  final eth = ref.watch(ethNetworkProvider);
  if (eth.isDisabled) return EthereumNetworkGasFees.disabled();
  return eth.fetchNetworkGasFees();
});

/// Max total fee in wei for chosen [maxFeePerGas] and [gasLimit].
final ethMaxTotalFeeProvider =
    FutureProvider.family<FeeEstimate, EthereumMaxFeeArgs>(
  (ref, args) {
    return ref.read(feeServiceProvider).estimateEthereumMaxFeeUsd(
          maxFeePerGas: args.maxFeePerGas,
          gasLimit: args.gasLimit,
        );
  },
);
