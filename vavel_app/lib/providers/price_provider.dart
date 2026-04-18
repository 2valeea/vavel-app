import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/price_service.dart';
import 'jupiter_tiktok_provider.dart' show jupiterTiktokInfoProvider;
import 'portfolio_provider.dart' show dioProvider;

/// Singleton [PriceProvider] backed by the shared [dioProvider].
final priceProviderInstance = Provider<PriceProvider>((ref) {
  return PriceProvider(ref.read(dioProvider));
});

/// Fetches all supported asset prices and auto-refreshes every 60 seconds.
final priceProvider = FutureProvider<Map<String, double>>((ref) async {
  // Schedule a self-invalidation so prices stay up-to-date automatically.
  final timer = Timer(const Duration(seconds: 60), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  // Keep pump.fun / Jupiter token quote in sync with the same interval.
  final jup = Timer(const Duration(seconds: 60), () {
    ref.invalidate(jupiterTiktokInfoProvider);
  });
  ref.onDispose(jup.cancel);

  return ref.read(priceProviderInstance).fetchPrices();
});
