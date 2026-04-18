import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset.dart' show kAssetTiktok;
import 'network_provider.dart';
import 'portfolio_provider.dart' show dioProvider;

/// Live token data from [Jupiter Token API](https://dev.jup.ag) (search by mint).
///
/// pump.fun / Token-2022 tokens are indexed there with icon, name, and USD price.
class JupiterTiktokToken {
  const JupiterTiktokToken({
    required this.name,
    required this.symbol,
    required this.icon,
    required this.decimals,
    required this.usdPrice,
  });

  final String name;
  final String symbol;
  final String? icon;
  final int decimals;
  final double? usdPrice;
}

final jupiterTiktokInfoProvider =
    FutureProvider.autoDispose<JupiterTiktokToken?>((ref) async {
  if (ref.watch(networkProvider) == AppNetwork.testnet) {
    return null;
  }
  final mint = kAssetTiktok.solanaMint;
  if (mint == null || mint.isEmpty) return null;
  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>(
    'https://lite-api.jup.ag/tokens/v2/search',
    queryParameters: {'query': mint},
  );
  final list = response.data;
  if (list == null || list.isEmpty) return null;
  Map<String, dynamic>? row;
  for (final e in list) {
    if (e is Map<String, dynamic> && (e['id'] as String?) == mint) {
      row = e;
      break;
    }
  }
  if (row == null) return null;
  final data = row;
  final usd = data['usdPrice'];
  final iconRaw = (data['icon'] as String?)?.trim();
  return JupiterTiktokToken(
    name: (data['name'] as String?)?.trim() ?? kAssetTiktok.name,
    symbol: (data['symbol'] as String?)?.trim() ?? kAssetTiktok.symbol,
    icon: (iconRaw == null || iconRaw.isEmpty) ? null : iconRaw,
    decimals: (data['decimals'] is int)
        ? data['decimals'] as int
        : (data['decimals'] as num?)?.toInt() ?? kAssetTiktok.decimals,
    usdPrice: (usd is num) ? usd.toDouble() : null,
  );
});
