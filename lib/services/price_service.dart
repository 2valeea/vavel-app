import 'package:dio/dio.dart';

/// Maps uppercase ticker symbols to CoinGecko coin IDs.
/// Assets absent from CoinGecko (e.g. VAVEL) are not included.
const _symbolToGeckoId = {
  'BTC': 'bitcoin',
  'ETH': 'ethereum',
  'SOL': 'solana',
  'TON': 'toncoin',
};

class PriceProvider {
  final Dio _dio;

  PriceProvider(this._dio);

  /// Returns the current USD price for a single [symbol] (e.g. "BTC", "ETH").
  ///
  /// Throws an [Exception] when [symbol] is not in the supported set.
  Future<double> getUsdPrice(String symbol) async {
    final id = _symbolToGeckoId[symbol.toUpperCase()];
    if (id == null) {
      throw Exception('Unsupported symbol for USD pricing: $symbol');
    }

    final resp = await _dio.get<Map<String, dynamic>>(
      'https://api.coingecko.com/api/v3/simple/price',
      queryParameters: {'ids': id, 'vs_currencies': 'usd'},
    );
    return (resp.data![id]!['usd'] as num).toDouble();
  }

  /// Returns USD prices for all supported assets in a single request.
  /// VAVEL is not on CoinGecko yet, so its key will be absent from the map.
  Future<Map<String, double>> fetchPrices() async {
    final ids = _symbolToGeckoId.values.join(',');
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.coingecko.com/api/v3/simple/price',
      queryParameters: {'ids': ids, 'vs_currencies': 'usd'},
    );
    final data = response.data!;
    final result = <String, double>{};
    for (final entry in _symbolToGeckoId.entries) {
      final coin = data[entry.value] as Map<String, dynamic>?;
      if (coin != null) {
        result[entry.value] = (coin['usd'] as num).toDouble();
      }
    }
    return result;
  }
}
