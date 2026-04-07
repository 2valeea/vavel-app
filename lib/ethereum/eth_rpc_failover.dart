import 'dart:async' show unawaited;
import 'dart:math' show min;

import 'package:http/http.dart' as http;

import '../http/safe_http_client.dart' show NonJsonRpcResponse, SafeHttpClient;

/// HTTP status codes that warrant rotating to the next endpoint.
/// 429 = rate-limited, 403 = blocked, 5xx = server error.
bool _shouldRotate(int statusCode) =>
    statusCode == 429 || statusCode == 403 || statusCode >= 500;

/// [http.BaseClient] that transparently routes requests through a list of
/// Ethereum JSON-RPC endpoints, rotating on 403 / 429 / 5xx responses.
///
/// Each endpoint is wrapped in [SafeHttpClient] so non-JSON error pages
/// surface as [NonJsonRpcResponse] rather than a cryptic [FormatException].
///
/// Exponential backoff is applied on 429 (rate-limit) responses:
///   attempt 0 → 1 s, attempt 1 → 2 s, attempt 2 → 4 s … capped at [maxDelay].
///
/// Usage:
/// ```dart
/// final failover = EthRpcFailover(rpcUrls: [
///   'https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY',  // primary
///   'https://rpc.ankr.com/eth',                        // backup
///   'https://eth.llamarpc.com',                        // public last-resort
/// ]);
/// final web3 = Web3Client('', failover); // URL is ignored — failover owns routing
/// ```
class EthRpcFailover extends http.BaseClient {
  final List<String> rpcUrls;
  final Duration maxDelay;

  int _i = 0;

  EthRpcFailover({
    required this.rpcUrls,
    this.maxDelay = const Duration(seconds: 16),
  }) : assert(rpcUrls.isNotEmpty, 'EthRpcFailover requires at least one URL');

  /// The currently active endpoint URL.
  String get _current => rpcUrls[_i];

  /// Advances to the next endpoint (round-robin).
  void _rotate() => _i = (_i + 1) % rpcUrls.length;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Object? lastError;

    for (var attempt = 0; attempt < rpcUrls.length; attempt++) {
      // Rewrite the request URL to the current endpoint.
      final rewritten = _rewrite(request, _current);
      final inner = SafeHttpClient(http.Client());

      try {
        final resp = await inner.send(rewritten);

        if (_shouldRotate(resp.statusCode)) {
          // 429: back off before rotating so we don't hammer the next node.
          if (resp.statusCode == 429) {
            await _backoff(attempt);
          }
          lastError = NonJsonRpcResponse(
            resp.statusCode,
            'HTTP ${resp.statusCode} from $_current',
            resp.headers,
          );
          _rotate();
          continue;
        }

        return resp;
      } on NonJsonRpcResponse catch (e) {
        lastError = e;
        if (_shouldRotate(e.statusCode)) {
          if (e.isRateLimited) await _backoff(attempt);
          _rotate();
          continue;
        }
        rethrow;
      } catch (e) {
        // Network error (socket, timeout, etc.) — try next endpoint.
        lastError = e;
        _rotate();
      } finally {
        unawaited(Future(() => inner.close()));
      }
    }

    // All endpoints exhausted.
    Error.throwWithStackTrace(
      lastError ?? Exception('EthRpcFailover: all endpoints failed'),
      StackTrace.current,
    );
  }

  /// Exponential backoff: 1 s, 2 s, 4 s … capped at [maxDelay].
  Future<void> _backoff(int attempt) {
    final ms = min(
      maxDelay.inMilliseconds,
      1000 * (1 << attempt), // 1 s × 2^attempt
    );
    return Future.delayed(Duration(milliseconds: ms));
  }

  /// Creates a copy of [original] with its URL replaced by [newUrl].
  ///
  /// `web3dart` always builds the full endpoint URL itself and passes it in
  /// the request, so we only need to swap the origin + path prefix.
  http.BaseRequest _rewrite(http.BaseRequest original, String newUrl) {
    final base = Uri.parse(newUrl);

    // Preserve the original path/query in case web3dart appended something,
    // but replace the scheme + authority with the failover endpoint.
    final rewrittenUri = original.url.replace(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path.isEmpty ? original.url.path : base.path,
      queryParameters: base.hasQuery
          ? {...base.queryParameters, ...original.url.queryParameters}
          : original.url.queryParameters.isEmpty
              ? null
              : original.url.queryParameters,
    );

    if (original is http.Request) {
      return http.Request(original.method, rewrittenUri)
        ..headers.addAll(original.headers)
        ..body = original.body
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects;
    }

    // StreamedRequest / MultipartRequest — rebuild as a streamed request.
    final streamed = http.StreamedRequest(original.method, rewrittenUri)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects;

    if (original is http.StreamedRequest) {
      original.finalize().pipe(streamed.sink);
    } else {
      unawaited(streamed.sink.close());
    }

    return streamed;
  }
}
