import 'dart:typed_data';

import 'package:web3dart/web3dart.dart';
import 'package:web3dart/json_rpc.dart' show RPCError;
import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart';

import '../config.dart';
import '../models/asset.dart' show AssetBalance;
import '../models/ethereum_gas_fees.dart';
import '../http/safe_http_client.dart' show SafeHttpClient;
import '../utils/ens_utils.dart';
import 'eth_rpc_failover.dart' show EthRpcFailover;

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

  /// ERC-20 [decimals] (0–255). Returns `null` if the call fails or ETH is disabled.
  Future<int?> getErc20Decimals(String contract) async {
    if (isDisabled) return null;
    try {
      final deployed = DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'ERC20'),
        EthereumAddress.fromHex(contract.trim()),
      );
      final decimalsFn = deployed.function('decimals');
      final result = await client.call(
        contract: deployed,
        function: decimalsFn,
        params: [],
      );
      final d = result.first;
      if (d is int) return d.clamp(0, 255);
      if (d is BigInt) return d.toInt().clamp(0, 255);
      return int.tryParse(d.toString())?.clamp(0, 255);
    } catch (_) {
      return null;
    }
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

  /// Fetches slow / standard / fast EIP-1559 tiers, or legacy gas price.
  Future<EthereumNetworkGasFees> fetchNetworkGasFees() async {
    if (isDisabled) return EthereumNetworkGasFees.disabled();
    try {
      final fees = await client.getGasInEIP1559();
      if (fees.length >= 3) {
        return EthereumNetworkGasFees(
          eip1559: true,
          slow: GasFeeTier.fromEip1559Fee(fees[0]),
          standard: GasFeeTier.fromEip1559Fee(fees[1]),
          fast: GasFeeTier.fromEip1559Fee(fees[2]),
        );
      }
      if (fees.isNotEmpty) {
        final t = GasFeeTier.fromEip1559Fee(fees.last);
        return EthereumNetworkGasFees(
          eip1559: true,
          slow: t,
          standard: t,
          fast: t,
        );
      }
    } on RPCError catch (e) {
      if (e.errorCode != -32014) rethrow;
    } catch (_) {
      // Fall through to legacy.
    }
    try {
      final gasPrice = await client.getGasPrice();
      final wei = gasPrice.getInWei;
      final tier = GasFeeTier(maxFeePerGas: wei, maxPriorityFeePerGas: wei);
      return EthereumNetworkGasFees(
        eip1559: false,
        slow: tier,
        standard: tier,
        fast: tier,
        legacyGasPriceWei: wei,
      );
    } catch (_) {
      return EthereumNetworkGasFees.disabled();
    }
  }

  // ── AssetBalance-returning methods (used by WalletService) ───────────────

  Future<AssetBalance> getBalance(String address) async {
    final wei = await getEthBalanceWei(address);
    return AssetBalance(assetId: 'eth', symbol: 'ETH', raw: wei, decimals: 18);
  }

  Future<AssetBalance> getTokenBalance(String address) async {
    if (isDisabled) {
      return AssetBalance(
        assetId: 'vaval',
        symbol: 'VAVAL',
        raw: BigInt.zero,
        decimals: _vavelDecimals,
      );
    }
    if (!RpcConfig.vavalTokenConfigured) {
      return AssetBalance(
        assetId: 'vaval',
        symbol: 'VAVAL',
        raw: BigInt.zero,
        decimals: _vavelDecimals,
      );
    }
    final raw = await getErc20Balance(
      contract: RpcConfig.vavalTokenContract.trim(),
      owner: address,
    );
    return AssetBalance(
      assetId: 'vaval',
      symbol: 'VAVAL',
      raw: raw,
      decimals: _vavelDecimals,
    );
  }

  // ── Send methods ──────────────────────────────────────────────────────────

  Future<String> sendEth({
    required EthPrivateKey senderKey,
    required String toAddress,
    required double ethAmount,
    required int chainId,
    int? gasLimit,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    BigInt? legacyGasPriceWei,
  }) async {
    if (isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true). '
          'Remove the flag or set --dart-define=ETH_RPC_URL=https://... to enable ETH.');
    }
    final weiAmount = BigInt.from((ethAmount * 1e18).toInt());
    final useEip1559 = maxFeePerGas != null && maxPriorityFeePerGas != null;
    final EtherAmount? maxFee =
        maxFeePerGas != null ? EtherAmount.inWei(maxFeePerGas) : null;
    final EtherAmount? maxPrio = maxPriorityFeePerGas != null
        ? EtherAmount.inWei(maxPriorityFeePerGas)
        : null;
    final EtherAmount? gasPrice = (!useEip1559 && legacyGasPriceWei != null)
        ? EtherAmount.inWei(legacyGasPriceWei)
        : null;
    return client.sendTransaction(
      senderKey,
      Transaction(
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.inWei(weiAmount),
        maxGas: gasLimit,
        gasPrice: gasPrice,
        maxFeePerGas: useEip1559 ? maxFee : null,
        maxPriorityFeePerGas: useEip1559 ? maxPrio : null,
      ),
      chainId: chainId,
    );
  }

  Future<String> sendToken({
    required EthPrivateKey senderKey,
    required String toAddress,
    required double vavelAmount,
    required int chainId,
    int? gasLimit,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    BigInt? legacyGasPriceWei,
  }) async {
    if (isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true). '
          'Remove the flag or set --dart-define=ETH_RPC_URL=https://... to enable ETH.');
    }
    if (!RpcConfig.vavalTokenConfigured) {
      throw StateError(
        'VAVAL token contract not configured. '
        'Pass --dart-define=VAVAL_TOKEN_CONTRACT=0x...',
      );
    }
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20Abi, 'VAVAL'),
      EthereumAddress.fromHex(RpcConfig.vavalTokenContract.trim()),
    );
    final transfer = contract.function('transfer');
    final rawAmount = BigInt.from((vavelAmount * 1e18).toInt());
    final useEip1559 = maxFeePerGas != null && maxPriorityFeePerGas != null;
    final EtherAmount? maxFee =
        maxFeePerGas != null ? EtherAmount.inWei(maxFeePerGas) : null;
    final EtherAmount? maxPrio = maxPriorityFeePerGas != null
        ? EtherAmount.inWei(maxPriorityFeePerGas) : null;
    final EtherAmount? gasPrice = (!useEip1559 && legacyGasPriceWei != null)
        ? EtherAmount.inWei(legacyGasPriceWei)
        : null;
    return client.sendTransaction(
      senderKey,
      Transaction.callContract(
        contract: contract,
        function: transfer,
        parameters: [EthereumAddress.fromHex(toAddress), rawAmount],
        maxGas: gasLimit,
        gasPrice: gasPrice,
        maxFeePerGas: useEip1559 ? maxFee : null,
        maxPriorityFeePerGas: useEip1559 ? maxPrio : null,
      ),
      chainId: chainId,
    );
  }

  /// Broadcasts a transaction built from a WalletConnect / JSON-RPC style map
  /// (`eth_sendTransaction` fields as hex strings).
  Future<String> sendWalletConnectTransaction({
    required EthPrivateKey credentials,
    required int chainId,
    required Map<String, dynamic> tx,
  }) async {
    if (isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true).');
    }
    final wallet = credentials.address.eip55With0x;
    final from = (tx['from'] as String?)?.trim();
    if (from != null &&
        from.replaceFirst(RegExp(r'^0x', caseSensitive: false), '').toLowerCase() !=
            wallet.replaceFirst(RegExp(r'^0x', caseSensitive: false), '').toLowerCase()) {
      throw StateError('Transaction "from" does not match this wallet.');
    }

    EthereumAddress? parseAddr(String? h) {
      if (h == null || h.isEmpty) return null;
      return EthereumAddress.fromHex(h);
    }

    BigInt? parseWei(String? key) {
      final v = tx[key];
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty || s == '0x') return BigInt.zero;
      return BigInt.parse(strip0x(s), radix: 16);
    }

    int? parseHexInt(String? key) {
      final v = tx[key];
      if (v == null) return null;
      if (v is int) return v;
      final s = v.toString();
      if (s.isEmpty) return null;
      return int.parse(strip0x(s), radix: 16);
    }

    final to = parseAddr(tx['to'] as String?);
    final valueWei = parseWei('value') ?? BigInt.zero;
    final dataHex = tx['data'] as String?;
    final Uint8List? data = (dataHex != null && dataHex.isNotEmpty)
        ? hexToBytes(dataHex)
        : null;

    final gas = parseHexInt('gas') ?? parseHexInt('gasLimit');
    final gasPriceWei = parseWei('gasPrice');
    final maxFeeWei = parseWei('maxFeePerGas');
    final maxPrioWei = parseWei('maxPriorityFeePerGas');
    final nonce = parseHexInt('nonce');

    final EtherAmount? gasPrice =
        gasPriceWei != null ? EtherAmount.inWei(gasPriceWei) : null;
    final EtherAmount? maxFee =
        maxFeeWei != null ? EtherAmount.inWei(maxFeeWei) : null;
    final EtherAmount? maxPrio =
        maxPrioWei != null ? EtherAmount.inWei(maxPrioWei) : null;

    final transaction = Transaction(
      to: to,
      maxGas: gas,
      gasPrice: (maxFee == null && maxPrio == null) ? gasPrice : null,
      maxFeePerGas: maxFee,
      maxPriorityFeePerGas: maxPrio,
      value: EtherAmount.inWei(valueWei),
      data: data,
      nonce: nonce,
    );

    return client.sendTransaction(
      credentials,
      transaction,
      chainId: chainId,
    );
  }

  // ── ENS (names live on Ethereum mainnet) ─────────────────────────────────

  static const _ensRegistryAddress =
      '0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e';

  /// Public mainnet endpoint used only for `eth_call` against the ENS contracts.
  static const _ensReadRpc = 'https://cloudflare-eth.com';

  static const _ensRegistryAbi = '''[
    {"name":"resolver","type":"function","stateMutability":"view",
     "inputs":[{"name":"node","type":"bytes32"}],
     "outputs":[{"type":"address"}]}
  ]''';

  static const _ensResolverAddrAbi = '''[
    {"name":"addr","type":"function","stateMutability":"view",
     "inputs":[{"name":"node","type":"bytes32"}],
     "outputs":[{"type":"address"}]}
  ]''';

  static final EthereumAddress _ensZero =
      EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');

  /// Resolves a normalized ENS name (e.g. `vitalik.eth`) to a lowercase `0x` address.
  ///
  /// Uses Ethereum **mainnet** state via [_ensReadRpc], independent of the wallet’s
  /// own chain (Sepolia users still resolve mainnet ENS the same way MetaMask does).
  Future<String?> resolveEnsName(String fullName) async {
    if (isDisabled) return null;
    final name = normalizeEnsNameForResolution(fullName);
    if (name == null) return null;

    final node = ensNamehash(name);
    final readClient = Web3Client(
      _ensReadRpc,
      SafeHttpClient(http.Client()),
    );
    try {
      final registry = DeployedContract(
        ContractAbi.fromJson(_ensRegistryAbi, 'ENSRegistry'),
        EthereumAddress.fromHex(_ensRegistryAddress),
      );
      final res = await readClient.call(
        contract: registry,
        function: registry.function('resolver'),
        params: [node],
      );
      final resolverAddr = res.first as EthereumAddress;
      if (resolverAddr.with0x == _ensZero.with0x) return null;

      final resolver = DeployedContract(
        ContractAbi.fromJson(_ensResolverAddrAbi, 'ENSResolver'),
        resolverAddr,
      );
      final out = await readClient.call(
        contract: resolver,
        function: resolver.function('addr'),
        params: [node],
      );
      final resolved = out.first as EthereumAddress;
      if (resolved.with0x == _ensZero.with0x) return null;
      return resolved.with0x;
    } catch (_) {
      return null;
    } finally {
      readClient.dispose();
    }
  }

  void dispose() => client.dispose();
}

const _erc20Abi = '''[
  {"type":"function","name":"balanceOf","stateMutability":"view",
   "inputs":[{"name":"account","type":"address"}],
   "outputs":[{"name":"","type":"uint256"}]},
  {"type":"function","name":"decimals","stateMutability":"view",
   "inputs":[],
   "outputs":[{"name":"","type":"uint8"}]},
  {"type":"function","name":"transfer","stateMutability":"nonpayable",
   "inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],
   "outputs":[{"name":"","type":"bool"}]}
]''';
