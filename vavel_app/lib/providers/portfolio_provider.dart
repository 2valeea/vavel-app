import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../ethereum/ethereum_adapter.dart' show EthereumProvider;
import '../models/ethereum_gas_fees.dart'
    show EthereumMaxFeeArgs, EthereumNetworkGasFees;
import '../models/fee_estimate.dart' show FeeEstimate;
import 'price_provider.dart' show priceProviderInstance;

/// Shared HTTP client for price feeds and Jupiter.
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {
      'User-Agent': 'WalletApp/1.0',
      'Accept': 'application/json',
    },
  ));
});

/// Ethereum JSON-RPC (same endpoints as [createWalletService] mainnet path).
final ethNetworkProvider = Provider<EthereumProvider>((ref) {
  if (RpcConfig.disableEth) return EthereumProvider.disabled();
  return EthereumProvider.withFailover(RpcConfig.ethRpcUrls);
});

const kEthTransferGasLimit = 21000;
const kErc20TransferGasLimit = 65000;

/// Live slow / standard / fast gas (or legacy) for send UI.
final ethereumNetworkGasFeesProvider =
    FutureProvider<EthereumNetworkGasFees>((ref) async {
  final eth = ref.watch(ethNetworkProvider);
  if (eth.isDisabled) return EthereumNetworkGasFees.disabled();
  return eth.fetchNetworkGasFees();
});

/// Max total fee in wei for chosen [maxFeePerGas] and [gasLimit], with USD preview.
final ethMaxTotalFeeProvider =
    FutureProvider.family<FeeEstimate, EthereumMaxFeeArgs>((ref, args) async {
  final prices = ref.read(priceProviderInstance);
  final ethPrice = await prices.getUsdPrice('ETH');
  final wei = args.maxFeePerGas * BigInt.from(args.gasLimit);
  final eth = wei.toDouble() / 1e18;
  return FeeEstimate(nativeAmount: wei, usd: eth * ethPrice);
});
