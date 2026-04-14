import 'package:dio/dio.dart';

/// Thrown for any non-success Solana RPC HTTP response.
///
/// [statusCode] is null when the request never reached the server
/// (connection refused, DNS failure, etc.).
class SolanaRpcException implements Exception {
  final int? statusCode;
  final dynamic body;

  const SolanaRpcException(this.statusCode, this.body);

  /// Whether this node actively rejected the API key (HTTP 403).
  bool get isForbidden => statusCode == 403;

  /// Whether the request never completed due to a network timeout.
  bool get isTimeout => statusCode == null && body == null;

  @override
  String toString() => 'SolanaRpcException(statusCode=$statusCode, body=$body)';
}

/// Low-level Solana JSON-RPC client for a single endpoint.
///
/// All major providers (Helius, Alchemy, QuickNode) embed authentication
/// inside the URL itself, so no extra header is needed — pass the full
/// authenticated URL as [rpcUrl].
///
/// Any non-200 HTTP response is converted to [SolanaRpcException].
class SolanaRpcClient {
  final Dio _dio;
  final String rpcUrl;

  SolanaRpcClient({required this.rpcUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: rpcUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Content-Type': 'application/json'},
          // Accept all HTTP responses so we can inspect the body before
          // deciding what to throw — prevents Dio from discarding a 403/429
          // HTML body as an unparseable DioException.
          validateStatus: (status) => status != null && status < 600,
        ));

  /// Sends a JSON-RPC [method] call and returns the raw response data.
  ///
  /// [params] defaults to an empty list so simple calls need no argument.
  /// The caller extracts `data['result']` and checks `data['error']`.
  Future<dynamic> call(String method, [List<dynamic> params = const []]) async {
    try {
      final resp = await _dio.post<dynamic>(
        '',
        data: {
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          'params': params,
        },
      );
      final status = resp.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        // 403 / 429 / 5xx land here without a DioException.
        throw SolanaRpcException(status, resp.data);
      }
      return resp.data;
    } on DioException catch (e) {
      // Network-level failures (DNS, timeout) never produce an HTTP response.
      throw SolanaRpcException(e.response?.statusCode, e.response?.data);
    }
  }
}
