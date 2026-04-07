import 'package:web3dart/web3dart.dart';
import 'package:web3dart/json_rpc.dart' show RPCError;
import 'package:http/http.dart' as http;

import '../models/asset.dart' show AssetBalance;
import '../http/safe_http_client.dart' show SafeHttpClient;
import 'eth_rpc_failover.dart' show EthRpcFailover;

const String vavelContractAddress =
    '0x12345...'; // replace with real contract address before release
const int _vavelDecimals = 18;

class EthereumProvider {
  final Web3Client? _client;

  Web3Client get client {
    assert(_client != null, 'ETH is disabled — no Web3Client available');
    return _client!;
  }

  /// Single-endpoint constructor. Wraps the client in [SafeHttpClient] so
  /// non-JSON error pages surface as [NonJsonRpcResponse].
  EthereumProvider(String rpcUrl)
      : _client = Web3Client(rpcUrl, SafeHttpClient(http.Client()));

  /// Multi-endpoint constructor with automatic round-robin failover and
  /// exponential backoff on 429 / 5xx responses.
  ///
  /// The first URL in [rpcUrls] is used as the primary and is also passed to
  /// [Web3Client] as the "canonical" URL (used by `getGasInEIP1559`).
  /// [EthRpcFailover] intercepts every HTTP request and rewrites the target
  /// URL to whichever endpoint is currently active.
  EthereumProvider.withFailover(List<String> rpcUrls)
      : _client = Web3Client(
          rpcUrls.first,
          EthRpcFailover(rpcUrls: rpcUrls),
        );

  EthereumProvider.withDefault()
      : _client = Web3Client(
            'https://eth.llamarpc.com', SafeHttpClient(http.Client()));

  /// Disabled stub — no [Web3Client] is created, zero network requests.
  /// All balance/fee methods return [BigInt.zero] immediately.
  /// Use with `--dart-define=DISABLE_ETH=true` during testing.
  EthereumProvider.disabled() : _client = null;

  bool get isDisabled => _client == null;

  // ── Primitive-returning methods (used by PortfolioService & fee logic) ───

  /// Returns the raw ETH balance in wei.
  Future<BigInt> getEthBalanceWei(String address) async {
    if (isDisabled) return BigInt.zero;
    final addr = EthereumAddress.fromHex(address);
    final balance = await client.getBalance(addr);
    return balance.getInWei;
  }

  /// Returns the raw ERC-20 token balance in the token's smallest unit.
  Future<BigInt> getErc20Balance({
    required String contract,
    required String owner,
  }) async {
    if (isDisabled) return BigInt.zero;
    final deployed = DeployedContract(
      ContractAbi.fromJson(_erc20Abi, 'ERC20'),
      EthereumAddress.fromHex(contract),
    );
    final balanceOf = deployed.function('balanceOf');
    final result = await client.call(
      contract: deployed,
      function: balanceOf,
      params: [EthereumAddress.fromHex(owner)],
    );
    return result.first as BigInt;
  }

  /// Estimates the fee in wei for a transaction needing [gasLimit] gas units.
  ///
  /// Tries EIP-1559 [maxFeePerGas] first via [getGasInEIP1559]; falls back to
  /// legacy [getGasPrice] if the node does not support EIP-1559 or returns
  /// -32014 "header not found".
  Future<BigInt> estimateTxFeeWei({required int gasLimit}) async {
    if (isDisabled) return BigInt.zero;
    try {
      final fees = await client.getGasInEIP1559();
      if (fees.isNotEmpty) {
        return fees.last.maxFeePerGas * BigInt.from(gasLimit);
      }
    } on RPCError catch (e) {
      // -32014: "header not found" — node doesn't support EIP-1559 fee history.
      // Any other RPCError is also recoverable: fall through to legacy.
      if (e.errorCode != -32014) rethrow;
    } catch (_) {
      // Unexpected error from EIP-1559 endpoint — fall through to legacy.
    }
    final gasPrice = await client.getGasPrice();
    return gasPrice.getInWei * BigInt.from(gasLimit);
  }

  // ── AssetBalance-returning methods (used by WalletService) ───────────────

  Future<AssetBalance> getBalance(String address) async {
    final wei = await getEthBalanceWei(address);
    return AssetBalance(assetId: 'eth', symbol: 'ETH', raw: wei, decimals: 18);
  }

  Future<AssetBalance> getTokenBalance(String address) async {
    if (vavelContractAddress.startsWith('0x12345')) {
      return AssetBalance(
        assetId: 'vavel',
        symbol: 'VAVEL',
        raw: BigInt.zero,
        decimals: _vavelDecimals,
      );
    }
    final raw = await getErc20Balance(
      contract: vavelContractAddress,
      owner: address,
    );
    return AssetBalance(
      assetId: 'vavel',
      symbol: 'VAVEL',
      raw: raw,
      decimals: _vavelDecimals,
    );
  }

  // ── Send methods ──────────────────────────────────────────────────────────

  Future<String> sendEth({
    required EthPrivateKey senderKey,
    required String toAddress,
    required double ethAmount,
  }) async {
    if (isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true). '
          'Remove the flag or set --dart-define=ETH_RPC_URL=https://... to enable ETH.');
    }
    final weiAmount = BigInt.from((ethAmount * 1e18).toInt());
    return client.sendTransaction(
      senderKey,
      Transaction(
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.inWei(weiAmount),
      ),
      chainId: 1,
    );
  }

  Future<String> sendToken({
    required EthPrivateKey senderKey,
    required String toAddress,
    required double vavelAmount,
  }) async {
    if (isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true). '
          'Remove the flag or set --dart-define=ETH_RPC_URL=https://... to enable ETH.');
    }
    if (vavelContractAddress.startsWith('0x12345')) {
      throw StateError('VAVEL contract address not configured');
    }
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20Abi, 'VAVEL'),
      EthereumAddress.fromHex(vavelContractAddress),
    );
    final transfer = contract.function('transfer');
    final rawAmount = BigInt.from((vavelAmount * 1e18).toInt());
    return client.sendTransaction(
      senderKey,
      Transaction.callContract(
        contract: contract,
        function: transfer,
        parameters: [EthereumAddress.fromHex(toAddress), rawAmount],
      ),
      chainId: 1,
    );
  }

  void dispose() => client.dispose();
}

const _erc20Abi = '''[
  {"type":"function","name":"balanceOf","stateMutability":"view",
   "inputs":[{"name":"account","type":"address"}],
   "outputs":[{"name":"","type":"uint256"}]},
  {"type":"function","name":"transfer","stateMutability":"nonpayable",
   "inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],
   "outputs":[{"name":"","type":"bool"}]}
]''';
