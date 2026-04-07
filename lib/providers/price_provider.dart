import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/price_service.dart';
import 'portfolio_provider.dart' show dioProvider;

/// Singleton [PriceProvider] backed by the shared [dioProvider].
final priceProviderInstance = Provider<PriceProvider>((ref) {
  return PriceProvider(ref.read(dioProvider));
});

/// Fetches all supported asset prices in a single CoinGecko request.
final priceProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.watch(priceProviderInstance).fetchPrices();
});
