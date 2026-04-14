import 'package:blockchain_utils/service/models/params.dart';
import 'package:http/http.dart' as http;
import 'package:ton_dart/ton_dart.dart';

/// HTTP provider that routes all requests to the TON Center v2 JSON-RPC API.
///
/// Pass the origin of the endpoint, e.g. `"https://toncenter.com"`.
/// The library appends `/api/v2/jsonRPC` automatically for every method call.
class TonCenterHttpProvider implements TonServiceProvider {
  TonCenterHttpProvider({
    required this.baseUrl,
    this.apiKey,
    http.Client? client,
    this.defaultTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  /// Base URL without trailing slash, e.g. "https://toncenter.com"
  final String baseUrl;

  final String? apiKey;

  final http.Client _client;
  final Duration defaultTimeout;

  @override
  TonApiType get api => TonApiType.tonCenter;

  @override
  Future<BaseServiceResponse<T>> doRequest<T>(
    TonRequestDetails params, {
    Duration? timeout,
  }) async {
    final uri = params.toUri(baseUrl);
    final headers = <String, String>{
      'content-type': 'application/json',
      if (apiKey != null) 'X-API-Key': apiKey!,
    };

    final http.Response response;
    if (params.type.isPostRequest) {
      response = await _client
          .post(uri, headers: headers, body: params.body())
          .timeout(timeout ?? defaultTimeout);
    } else {
      response = await _client
          .get(uri, headers: headers)
          .timeout(timeout ?? defaultTimeout);
    }
    return params.parseResponse(response.bodyBytes, response.statusCode);
  }
}
