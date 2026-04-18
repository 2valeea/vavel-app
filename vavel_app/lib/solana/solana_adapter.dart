import 'dart:convert';
import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cryptography/cryptography.dart';

import '../crypto/solana_keypair.dart';
import '../models/asset.dart' show AssetBalance;
import 'solana_rpc_client.dart' show SolanaRpcException;
import 'solana_rpc_failover.dart';

/// Dart equivalent of the TypeScript `SolanaAdapter` class.
///
/// Uses [SolanaRpcFailover] for transparent multi-endpoint failover.
///
/// Pass a fully-authenticated URL as [endpoint] — Helius, Alchemy, and
/// QuickNode all embed the key in the URL path or query parameter.
///
/// Transaction signing uses the `cryptography` package (Ed25519) and
/// transaction serialization follows the Solana wire format:
///   compact-u16 array lengths, little-endian u64 amounts.
class SolanaAdapter {
  /// Token-2022 (spl-token-2022) program id.
  static const String token2022ProgramId =
      'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb';

  /// Primary Solana cluster RPC endpoint (may contain an embedded API key).
  final String endpoint;

  final SolanaRpcFailover _failover;

  SolanaAdapter({
    this.endpoint = 'https://api.mainnet-beta.solana.com',
    List<String> fallbackEndpoints = const [],
  }) : _failover = SolanaRpcFailover([
          endpoint,
          ...fallbackEndpoints.where((e) => e != endpoint),
        ]);

  // ── public API ────────────────────────────────────────────────────────────

  /// Derives the base58 Solana address from [kp].
  ///
  /// Equivalent of `SolanaAdapter.addressFromKeypair(kp)` in TypeScript.
  String addressFromKeypair(SolanaKeyPair kp) => kp.address;

  /// Returns the SOL balance of [address] as an [AssetBalance].
  Future<AssetBalance> getBalance(String address) async {
    final result = await _rpc('getBalance', [address]);
    final lamports = BigInt.from(result['value'] as int);
    return AssetBalance(
      assetId: 'sol',
      symbol: 'SOL',
      raw: lamports,
      decimals: 9,
    );
  }

  /// Token-2022 balance for [owner] and [mint] (e.g. pump.fun coins).
  ///
  /// Returns zero with [defaultDecimals] when the wallet has no ATA for this mint.
  Future<AssetBalance> getToken2022Balance(
    String owner,
    String mint, {
    String assetId = 'tiktok',
    String symbol = 'tik-tok',
    int defaultDecimals = 6,
  }) async {
    final result = await _rpc('getTokenAccountsByOwner', [
      owner,
      {'programId': token2022ProgramId},
      const {'encoding': 'jsonParsed'},
    ]);
    final value = (result is Map && result['value'] is List)
        ? result['value'] as List<dynamic>
        : const <dynamic>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      final account = entry['account'];
      if (account is! Map) continue;
      final data = account['data'];
      if (data is! Map) continue;
      final parsed = data['parsed'];
      if (parsed is! Map) continue;
      final info = parsed['info'];
      if (info is! Map) continue;
      if ((info['mint'] as String?) != mint) continue;
      final tokenAmount = info['tokenAmount'];
      if (tokenAmount is! Map) continue;
      final amountStr = tokenAmount['amount'] as String? ?? '0';
      final raw = BigInt.tryParse(amountStr) ?? BigInt.zero;
      final dec = (tokenAmount['decimals'] is int)
          ? tokenAmount['decimals'] as int
          : (tokenAmount['decimals'] is num)
              ? (tokenAmount['decimals'] as num).toInt()
              : defaultDecimals;
      return AssetBalance(
        assetId: assetId,
        symbol: symbol,
        raw: raw,
        decimals: dec,
      );
    }
    return AssetBalance(
      assetId: assetId,
      symbol: symbol,
      raw: BigInt.zero,
      decimals: defaultDecimals,
    );
  }

  /// Checks whether the primary RPC node (and its fallbacks) is reachable.
  ///
  /// Returns `true` if the cluster reports `'ok'`.
  /// Throws [SolanaRpcException] if every endpoint fails — callers can
  /// inspect [SolanaRpcException.isForbidden] to decide whether to prompt
  /// the user to configure a different RPC node.
  Future<bool> checkHealth() async {
    final result = await _rpc('getHealth');
    return result == 'ok';
  }

  /// Signs and broadcasts a SOL transfer.
  ///
  /// Parameters mirror the TypeScript `sendSol({ from, toBase58, sol })`:
  ///   - [from]      – the sender keypair (provides both key and address)
  ///   - [toBase58]  – destination address in base58
  ///   - [sol]       – amount as a `double`, e.g. `0.05`
  ///
  /// Returns the transaction signature string on success.
  Future<String> sendSol({
    required SolanaKeyPair from,
    required String toBase58,
    required double sol,
  }) async {
    final lamports = BigInt.from((sol * 1e9).round());

    // 1. Fetch recent blockhash
    final bhResult = await _rpc('getLatestBlockhash', [
      {'commitment': 'finalized'}
    ]);
    final blockhashB58 = bhResult['value']['blockhash'] as String;
    final blockhash = _decodeBase58(blockhashB58);

    // 2. Decode addresses
    final fromBytes = Uint8List.fromList(from.publicKey);
    final toBytes = _decodeBase58(toBase58);

    // 3. Build the message (the part that gets signed)
    final message = _buildTransferMessage(
      from: fromBytes,
      to: toBytes,
      lamports: lamports,
      blockhash: blockhash,
    );

    // 4. Sign with Ed25519
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(from.privateKey);
    final sig = await algorithm.sign(message, keyPair: keyPair);

    // 5. Assemble final transaction
    final tx = _buildTransaction(message: message, signature: sig.bytes);

    // 6. Broadcast — sendTransaction expects base64 with encoding hint
    final txSig = await _rpc('sendTransaction', [
      base64Encode(tx),
      {'encoding': 'base64'},
    ]);

    return txSig as String;
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Delegates to [SolanaRpcFailover.call] and unwraps the JSON-RPC envelope.
  Future<dynamic> _rpc(String method, [List<dynamic> params = const []]) async {
    final data = await _failover.call(method, params);
    if (data is Map && data.containsKey('error')) {
      throw Exception('Solana RPC error: ${data['error']}');
    }
    return (data as Map)['result'];
  }

  /// Decodes a Solana base58-encoded address or blockhash to raw bytes.
  static Uint8List _decodeBase58(String s) =>
      Uint8List.fromList(Base58Decoder.decode(s));

  // ── Solana transaction serialization ─────────────────────────────────────

  /// Encodes [n] as a Solana compact-u16 (1-3 bytes).
  static List<int> _compactU16(int n) {
    if (n < 0x80) return [n];
    if (n < 0x4000) return [(n & 0x7f) | 0x80, n >> 7];
    return [(n & 0x7f) | 0x80, ((n >> 7) & 0x7f) | 0x80, n >> 14];
  }

  /// Encodes [value] as an 8-byte little-endian uint64.
  static List<int> _u64Le(BigInt value) {
    final bytes = <int>[];
    var v = value;
    for (int i = 0; i < 8; i++) {
      bytes.add((v & BigInt.from(0xff)).toInt());
      v >>= 8;
    }
    return bytes;
  }

  /// Builds the Solana message header + body for a SystemInstruction::Transfer.
  ///
  /// Wire layout (message only, without signature prefix):
  ///   header (3 bytes) | accounts (compact-u16 + 3×32 bytes) |
  ///   recent_blockhash (32 bytes) | instructions (compact-u16 + instruction)
  static List<int> _buildTransferMessage({
    required Uint8List from, // 32 bytes — sender public key
    required Uint8List to, // 32 bytes — recipient public key
    required BigInt lamports,
    required Uint8List blockhash, // 32 bytes — recent blockhash
  }) {
    // Account order: [from(signer), to, SystemProgram(readonly)]
    const systemProgram = <int>[
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]; // 11111111111111111111111111111111

    // SystemInstruction::Transfer data: discriminant(u32) = 2, lamports(u64)
    final instructionData = [2, 0, 0, 0, ..._u64Le(lamports)];

    return [
      // Message header
      1, // num_required_signatures
      0, // num_readonly_signed_accounts
      1, // num_readonly_unsigned_accounts (SystemProgram)
      // Account addresses
      ..._compactU16(3),
      ...from,
      ...to,
      ...systemProgram,
      // Recent blockhash
      ...blockhash,
      // Instructions
      ..._compactU16(1), // 1 instruction
      2, // program_id_index → SystemProgram at [2]
      ..._compactU16(2), // 2 account indices
      0, 1, // from = accounts[0], to = accounts[1]
      ..._compactU16(instructionData.length),
      ...instructionData,
    ];
  }

  /// Wraps [message] with the compact-u16 signature count and the [signature].
  static List<int> _buildTransaction({
    required List<int> message,
    required List<int> signature, // 64 bytes
  }) {
    return [..._compactU16(1), ...signature, ...message];
  }
}
