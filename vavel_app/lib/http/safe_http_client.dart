import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown when an RPC endpoint returns a non-JSON body (e.g. an HTML
/// Cloudflare error page or a plain-text 403 response).
///
/// The [statusCode], first 200 chars of [bodyStart], and response [headers]
/// are preserved so callers can log or display a meaningful error message.
///
/// Used across all chains (Ethereum, TON, Solana, Bitcoin).
class NonJsonRpcResponse implements Exception {
  final int statusCode;
  final String bodyStart;
  final Map<String, String> headers;

  const NonJsonRpcResponse(this.statusCode, this.bodyStart, this.headers);

  bool get isForbidden => statusCode == 403;
  bool get isRateLimited => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;

  /// True when the response indicates an authentication / authorization failure.
  ///
  /// Covers:
  ///   • HTTP 401 / 403 status codes
  ///   • Plain-text messages from llamarpc, Alchemy, Infura, QuickNode
  ///   • Cloudflare HTML challenge / attention pages
  ///   • Common API-gateway "missing / invalid key" messages
  bool get isAuthError {
    if (statusCode == 401 || statusCode == 403) return true;
    final lower = bodyStart.toLowerCase();
    return lower.contains('must be auth') || // llamarpc "Must be authenticated"
        lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('access denied') ||
        lower.contains('access is denied') ||
        lower.contains('permission denied') ||
        lower.contains('not allowed') ||
        lower.contains('api key') || // "Invalid API key", "Missing API key"
        lower.contains('apikey') ||
        lower.contains('invalid key') ||
        lower.contains('missing key') ||
        lower.contains('missing project') || // Infura "Missing project id"
        lower.contains('project id') ||
        lower.contains('invalid project') ||
        lower.contains('authentication required') ||
        lower.contains(
            'attention required') || // Cloudflare challenge page title
        lower.contains('checking your browser') || // Cloudflare bot check
        lower.contains('just a moment') || // Cloudflare "Just a moment..." page
        lower.contains('cloudflare') || // any Cloudflare-branded block
        lower.contains('<html') &&
            ( // generic HTML auth page heuristic
                lower.contains('401') ||
                    lower.contains('403') ||
                    lower.contains('login') ||
                    lower.contains('sign in'));
  }

  /// Returns a short, human-readable description suitable for display in the UI.
  String get userMessage {
    if (isAuthError) {
      return 'RPC endpoint requires an API key or access is denied (HTTP $statusCode). '
          'Pass a valid --dart-define=ETH_RPC_URL=https://... with your API key.';
    }
    if (isRateLimited) {
      return 'RPC endpoint is rate-limited (HTTP 429). '
          'Use an authenticated endpoint with --dart-define=ETH_RPC_URL=https://...';
    }
    return 'RPC endpoint returned a non-JSON response (HTTP $statusCode): "$bodyStart"';
  }

  @override
  String toString() =>
      'NonJsonRpcResponse(status=$statusCode, body="$bodyStart", headers=$headers)';
}

/// [http.BaseClient] wrapper that peeks at every response and throws
/// [NonJsonRpcResponse] when the body is not JSON.
///
/// This prevents cryptic `FormatException`s when an API returns an HTML error
/// page (Cloudflare, WAF, CDN) or a plain-text auth error instead of a valid
/// JSON-RPC response.
///
/// NOTE: validation is done on the body content itself, not the Content-Type
/// header. Some servers (e.g. llamarpc) return `Content-Type: application/json`
/// alongside a plain-text body like "Must be authenticated", which would fool
/// a header-based check and let web3dart call jsonDecode() on non-JSON content.
///
/// Used across all chains (Ethereum, TON, Solana, Bitcoin).
///
/// Usage:
/// ```dart
/// final client = SafeHttpClient(http.Client());
/// ```
class SafeHttpClient extends http.BaseClient {
  final http.Client _inner;

  SafeHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = await _inner.send(request);

    // Buffer the full response body so we can inspect it.
    final bytes = await resp.stream.toBytes();
    final body = utf8.decode(bytes, allowMalformed: true);

    final trimmed = body.trimLeft();
    // Validate the body itself, not the Content-Type header: some servers
    // return "Must be authenticated" or other plain-text error messages with
    // `Content-Type: application/json`, which would fool a header-based check
    // and let web3dart call jsonDecode() on non-JSON content.
    final looksJson = trimmed.startsWith('{') || trimmed.startsWith('[');

    if (!looksJson) {
      final preview = body.length > 200 ? body.substring(0, 200) : body;
      throw NonJsonRpcResponse(resp.statusCode, preview, resp.headers);
    }

    // Reconstruct the response with the already-consumed byte stream.
    return http.StreamedResponse(
      Stream.value(bytes),
      resp.statusCode,
      headers: resp.headers,
      reasonPhrase: resp.reasonPhrase,
      request: resp.request,
      isRedirect: resp.isRedirect,
      persistentConnection: resp.persistentConnection,
    );
  }

  @override
  void close() => _inner.close();
}
