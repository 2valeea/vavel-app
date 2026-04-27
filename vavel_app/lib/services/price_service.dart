import 'package:dio/dio.dart';

const _symbolToGeckoId = {
  'ETH': 'ethereum',
  'SOL': 'solana',
  'TON': 'toncoin',
};

const _cryptoCompareSymbols = ['ETH', 'SOL', 'TON'];

class PriceProvider {
  final Dio _dio;

  PriceProvider(this._dio);

  /// Returns the current USD price for a single [symbol] (e.g. "SOL", "TON").
  ///
  /// Throws an [Exception] when [symbol] is not in the supported set.
  Future<double> getUsdPrice(String symbol) async {
    final prices = await fetchPrices();
    final price = prices[symbol.toUpperCase()];
    if (price == null) {
      throw Exception('Unsupported symbol for USD pricing: $symbol');
    }
    return price;
  }

  /// Returns USD prices for all supported assets in a single request.
  ///
  /// Tries CryptoCompare first (CORS-friendly for web); falls back to
  /// CoinGecko if the primary request fails.
  ///
  Future<Map<String, double>> fetchPrices() async {
    try {
      return await _fetchFromCryptoCompare();
    } catch (_) {
      return _fetchFromCoinGecko();
    }
  }

  /// CryptoCompare public API — allows browser CORS requests without an API key.
  Future<Map<String, double>> _fetchFromCryptoCompare() async {
    final fsyms = _cryptoCompareSymbols.join(',');
    final response = await _dio.get<Map<String, dynamic>>(
      'https://min-api.cryptocompare.com/data/pricemulti',
      queryParameters: {'fsyms': fsyms, 'tsyms': 'USD'},
    );
    final data = response.data!;
    final result = <String, double>{};
    for (final symbol in _cryptoCompareSymbols) {
      final entry = data[symbol] as Map<String, dynamic>?;
      if (entry != null) {
        result[symbol] = (entry['USD'] as num).toDouble();
      }
    }
    if (result.isEmpty) throw Exception('CryptoCompare returned empty data');
    return result;
  }

  /// CoinGecko fallback — may be rate-limited on the free tier.
  /// Returns prices keyed by uppercase ticker symbol (e.g. 'BTC').
  Future<Map<String, double>> _fetchFromCoinGecko() async {
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
        result[entry.key] = (coin['usd'] as num).toDouble();
      }
    }
    return result;
  }
}
