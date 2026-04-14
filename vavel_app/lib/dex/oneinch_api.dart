import 'dart:convert';
import 'package:http/http.dart' as http;

class OneInchApi {
  static const String baseUrl =
      'https://api.1inch.dev/swap/v5.2/1'; // 1 = Ethereum Mainnet
  final String apiKey;

  OneInchApi({required this.apiKey});

  Future<Map<String, dynamic>> getQuote({
    required String fromTokenAddress,
    required String toTokenAddress,
    required String amount,
  }) async {
    final url = Uri.parse(
        '$baseUrl/quote?fromTokenAddress=$fromTokenAddress&toTokenAddress=$toTokenAddress&amount=$amount');
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get quote: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getSwapTx({
    required String fromTokenAddress,
    required String toTokenAddress,
    required String amount,
    required String fromAddress,
    required String slippage,
  }) async {
    final url = Uri.parse(
        '$baseUrl/swap?fromTokenAddress=$fromTokenAddress&toTokenAddress=$toTokenAddress&amount=$amount&fromAddress=$fromAddress&slippage=$slippage');
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $apiKey'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get swap tx: ${response.body}');
    }
  }
}
