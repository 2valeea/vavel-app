import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vavel_app/http/safe_http_client.dart';

/// Returns a [MockClient] that responds with the given [statusCode], [body],
/// and optional [contentType] to every request.
http.Client _mockClient({
  required int statusCode,
  required String body,
  String contentType = 'application/json',
}) {
  return MockClient((_) async => http.Response(
        body,
        statusCode,
        headers: {'content-type': contentType},
      ));
}

void main() {
  group('SafeHttpClient', () {
    final requestUri = Uri.parse('https://eth.llamarpc.com');

    // ── Core bug regression ───────────────────────────────────────────────────

    test(
      'throws NonJsonRpcResponse when body is "Must be authenticated" '
      'even if Content-Type is application/json',
      () async {
        final client = SafeHttpClient(
          _mockClient(
            statusCode: 200,
            body: 'Must be authenticated',
            contentType: 'application/json',
          ),
        );

        await expectLater(
          () => client.get(requestUri),
          throwsA(
            isA<NonJsonRpcResponse>()
                .having((e) => e.statusCode, 'statusCode', 200)
                .having((e) => e.isAuthError, 'isAuthError', true)
                .having(
                  (e) => e.bodyStart,
                  'bodyStart',
                  contains('Must be authenticated'),
                ),
          ),
        );
      },
    );

    // ── isAuthError detection ─────────────────────────────────────────────────

    test('isAuthError is true for HTTP 401', () async {
      final client = SafeHttpClient(
        _mockClient(
            statusCode: 401, body: 'Unauthorized', contentType: 'text/plain'),
      );
      await expectLater(
        () => client.get(requestUri),
        throwsA(
          isA<NonJsonRpcResponse>()
              .having((e) => e.isAuthError, 'isAuthError', true),
        ),
      );
    });

    test('isAuthError is true for HTTP 403', () async {
      final client = SafeHttpClient(
        _mockClient(
            statusCode: 403, body: 'Forbidden', contentType: 'text/plain'),
      );
      await expectLater(
        () => client.get(requestUri),
        throwsA(
          isA<NonJsonRpcResponse>()
              .having((e) => e.isAuthError, 'isAuthError', true),
        ),
      );
    });

    test('isAuthError is true for plain-text "forbidden" body (HTTP 200)',
        () async {
      final client = SafeHttpClient(
        _mockClient(
            statusCode: 200, body: 'forbidden', contentType: 'text/plain'),
      );
      await expectLater(
        () => client.get(requestUri),
        throwsA(
          isA<NonJsonRpcResponse>()
              .having((e) => e.isAuthError, 'isAuthError', true),
        ),
      );
    });

    // ── isRateLimited ─────────────────────────────────────────────────────────

    test('isRateLimited is true for HTTP 429 with non-JSON body', () async {
      final client = SafeHttpClient(
        _mockClient(
            statusCode: 429,
            body: 'Too Many Requests',
            contentType: 'text/plain'),
      );
      await expectLater(
        () => client.get(requestUri),
        throwsA(
          isA<NonJsonRpcResponse>()
              .having((e) => e.isRateLimited, 'isRateLimited', true),
        ),
      );
    });

    // ── HTML error pages ──────────────────────────────────────────────────────

    test('throws NonJsonRpcResponse for Cloudflare HTML page', () async {
      const html = '<html><head><title>Just a moment...</title></head></html>';
      final client = SafeHttpClient(
        _mockClient(statusCode: 403, body: html, contentType: 'text/html'),
      );
      await expectLater(
        () => client.get(requestUri),
        throwsA(isA<NonJsonRpcResponse>()),
      );
    });

    // ── Valid JSON passes through ─────────────────────────────────────────────

    test('passes through a valid JSON-RPC result object', () async {
      const jsonBody = '{"jsonrpc":"2.0","id":1,"result":"0x1"}';
      final client = SafeHttpClient(
        _mockClient(statusCode: 200, body: jsonBody),
      );

      final response = await client.get(requestUri);
      expect(response.body, equals(jsonBody));
      expect(response.statusCode, equals(200));
    });

    test('passes through a valid JSON-RPC array response', () async {
      const jsonBody = '[{"id":1},{"id":2}]';
      final client = SafeHttpClient(
        _mockClient(statusCode: 200, body: jsonBody),
      );

      final response = await client.get(requestUri);
      expect(response.body, equals(jsonBody));
    });

    test('passes through JSON with leading whitespace / BOM', () async {
      const jsonBody = '   \n{"jsonrpc":"2.0","result":null}';
      final client = SafeHttpClient(
        _mockClient(statusCode: 200, body: jsonBody),
      );

      final response = await client.get(requestUri);
      expect(response.body, equals(jsonBody));
    });

    // ── bodyStart truncation ──────────────────────────────────────────────────

    test('bodyStart is capped at 200 chars for very long non-JSON bodies',
        () async {
      final longBody = 'x' * 500;
      final client = SafeHttpClient(
        _mockClient(statusCode: 200, body: longBody, contentType: 'text/plain'),
      );
      await expectLater(
        () => client.get(requestUri),
        throwsA(
          isA<NonJsonRpcResponse>()
              .having((e) => e.bodyStart.length, 'bodyStart.length', 200),
        ),
      );
    });
  });
}
