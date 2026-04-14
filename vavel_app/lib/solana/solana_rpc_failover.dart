import 'solana_rpc_client.dart';

/// Wraps multiple [SolanaRpcClient] instances and automatically rotates
/// to the next endpoint on retriable [SolanaRpcException]s.
///
/// Rotation is round-robin and persists across calls, so a permanently
/// broken primary endpoint is skipped on subsequent requests without
/// re-trying it every time.
///
/// Non-retriable errors (e.g. a malformed request that returns a 400) are
/// re-thrown immediately without rotating.
///
/// Usage:
/// ```dart
/// final failover = SolanaRpcFailover([
///   'https://mainnet.helius-rpc.com/?api-key=YOUR_KEY',
///   'https://api.mainnet-beta.solana.com',
///   'https://solana-mainnet.g.alchemy.com/v2/demo',
/// ]);
/// final result = await failover.call('getBalance', [address]);
/// ```
class SolanaRpcFailover {
  final List<String> rpcUrls;

  // Index of the currently active endpoint.
  int _i = 0;

  SolanaRpcFailover(this.rpcUrls);

  /// The currently active [SolanaRpcClient].
  SolanaRpcClient get client => SolanaRpcClient(rpcUrl: rpcUrls[_i]);

  /// Advances to the next endpoint (wraps around).
  void rotate() => _i = (_i + 1) % rpcUrls.length;

  /// Returns `true` for HTTP statuses that indicate the endpoint itself
  /// is the problem rather than the request:
  ///   - 403 — API key rejected
  ///   - 429 — rate-limited
  ///   - 5xx — server-side error
  ///
  /// Null status (network/DNS failure) is also considered retriable.
  bool _shouldRotate(SolanaRpcException e) {
    final code = e.statusCode;
    return code == null || code == 403 || code == 429 || code >= 500;
  }

  /// Calls [method] with [params], rotating endpoints on retriable errors.
  ///
  /// Re-throws immediately on non-retriable errors (e.g. 400 bad request).
  /// Re-throws the last exception after all endpoints have been tried.
  Future<dynamic> call(String method, [List<dynamic> params = const []]) async {
    for (var attempt = 0; attempt < rpcUrls.length; attempt++) {
      try {
        return await client.call(method, params);
      } on SolanaRpcException catch (e) {
        if (_shouldRotate(e)) {
          rotate();
          if (attempt == rpcUrls.length - 1) {
            rethrow;
          }
          continue;
        }
        rethrow;
      }
    }
    throw StateError('Unreachable');
  }
}
