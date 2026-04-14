import 'package:http/http.dart' as http;
import 'package:ton_dart/ton_dart.dart';

import 'ton_provider.dart';
import 'safe_http_client.dart' show SafeHttpClient;
import '../models/asset.dart' show AssetBalance;

/// Configuration for connecting to the TON network via TonCenter v2.
class TonConfig {
  /// Full TonCenter v2 JSON-RPC endpoint, e.g.
  ///   "https://toncenter.com/api/v2/jsonRPC"        (mainnet)
  ///   "https://testnet.toncenter.com/api/v2/jsonRPC" (testnet)
  final String endpoint;

  /// Optional TonCenter API key.
  final String? apiKey;

  /// Set to `true` when using the testnet endpoint.
  /// Affects wallet address chain selection and test-only address flags.
  final bool testnet;

  /// Optional HTTP client. Defaults to [SafeHttpClient] wrapping [http.Client]
  /// so non-JSON error pages are surfaced as [NonJsonRpcResponse] instead of
  /// a cryptic [FormatException].
  final http.Client? httpClient;

  const TonConfig({
    required this.endpoint,
    this.apiKey,
    this.testnet = false,
    this.httpClient,
  });
}

/// Dart equivalent of the TypeScript `TonAdapter` class.
///
/// Mirrors the full API surface:
///   - [openWallet]   – returns a live [WalletV4] contract bound to the RPC.
///   - [getAddress]   – derives the user-friendly wallet address from a public key.
///   - [getBalance]   – queries the balance of any TON address.
///   - [sendTon]      – signs and broadcasts a simple TON transfer.
///
/// Key differences from the TypeScript version:
///   • [List<int>] replaces `Buffer` for key material.
///   • The seqno is always fetched on-chain automatically by `sendTransfer`;
///     an explicit `seqno` argument is kept for API compatibility but
///     currently not forwarded to ton_dart (which does not expose that bypass).
class TonAdapter {
  final TonConfig config;
  late final TonProvider _rpc;

  TonAdapter(this.config) {
    // Extract the URL origin so ton_dart can append /api/v2/jsonRPC itself.
    final origin = Uri.parse(config.endpoint).origin;
    _rpc = TonProvider(
      TonCenterHttpProvider(
        baseUrl: origin,
        apiKey: config.apiKey,
        client: config.httpClient ?? SafeHttpClient(http.Client()),
      ),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  WalletV4 _buildWallet({
    required List<int> publicKey,
    int workchain = 0,
  }) {
    final chain = (workchain == -1 || config.testnet)
        ? TonChainId.testnet
        : TonChainId.mainnet;
    return WalletV4.create(
      chain: chain,
      publicKey: publicKey,
      bounceableAddress: false, // consistent with bounce: false in TypeScript
    );
  }

  // ── public API ───────────────────────────────────────────────────────────

  /// Returns a live [WalletV4] contract instance bound to the RPC provider.
  ///
  /// Equivalent to `TonClient.open(WalletContractV4.create({...}))` in TS.
  WalletV4 openWallet({
    required List<int> publicKey,
    int workchain = 0,
  }) {
    return _buildWallet(publicKey: publicKey, workchain: workchain);
  }

  /// Derives the user-friendly (non-bounceable) wallet address for [publicKey].
  String getAddress({
    required List<int> publicKey,
    int workchain = 0,
  }) {
    final wallet = _buildWallet(publicKey: publicKey, workchain: workchain);
    return wallet.address.toFriendlyAddress(
      bounceable: false,
      testOnly: config.testnet,
    );
  }

  /// Returns the balance of [address] in nanotons and as a decimal TON string.
  Future<AssetBalance> getBalance(String address) async {
    final nanotons = await _rpc.request(
      TonCenterGetAddressBalance(address),
    );
    return AssetBalance(
      assetId: 'ton',
      symbol: 'TON',
      raw: nanotons,
      decimals: 9,
    );
  }

  /// Signs and broadcasts a TON transfer.
  ///
  /// Parameters:
  ///   - [publicKey]  – 32-byte Ed25519 public key.
  ///   - [secretKey]  – 32-byte Ed25519 seed / private key.
  ///   - [to]         – destination address (any TON address format).
  ///   - [ton]        – amount as a decimal string, e.g. `"0.05"`.
  ///   - [seqno]      – reserved for API compatibility; seqno is always
  ///                    fetched from the chain by ton_dart automatically.
  ///   - [workchain]  – 0 for mainnet (default), -1 for masterchain.
  Future<void> sendTon({
    required List<int> publicKey,
    required List<int> secretKey,
    required String to,
    required String ton,
    int? seqno, // currently unused; ton_dart fetches it on-chain
    int workchain = 0,
  }) async {
    final wallet = _buildWallet(publicKey: publicKey, workchain: workchain);
    final signer = TonPrivateKey.fromBytes(secretKey);

    await wallet.sendTransfer(
      params: VersionedTransferParams(
        privateKey: signer,
        messages: [
          OutActionSendMsg(
            outMessage: TonHelper.internal(
              destination: TonAddress(to),
              amount: TonHelper.toNano(ton),
              bounce: false,
            ),
          ),
        ],
      ),
      rpc: _rpc,
    );
  }
}
