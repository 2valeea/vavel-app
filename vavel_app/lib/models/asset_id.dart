import 'package:flutter/material.dart';
import 'asset.dart';

enum AssetId { vaval, eth, sol, tiktok, ton }

extension AssetInfo on AssetId {
  Asset get asset => kAssets.firstWhere((a) => a.id == name);

  String get label => asset.name;
  String get ticker => asset.symbol;
  String? get geckoId => asset.geckoId;

  Color get color {
    switch (this) {
      case AssetId.vaval:
        return const Color(0xFFE8A317);
      case AssetId.eth:
        return const Color(0xFF627EEA);
      case AssetId.sol:
        return const Color(0xFF9945FF);
      case AssetId.tiktok:
        return const Color(0xFFFF2E8B);
      case AssetId.ton:
        return const Color(0xFF0098EA);
    }
  }

  IconData get icon {
    switch (this) {
      case AssetId.vaval:
        return Icons.token_outlined;
      case AssetId.eth:
        return Icons.currency_exchange;
      case AssetId.sol:
        return Icons.blur_circular;
      case AssetId.tiktok:
        return Icons.bolt;
      case AssetId.ton:
        return Icons.hub_outlined;
    }
  }
}
