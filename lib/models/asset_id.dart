import 'package:flutter/material.dart';
import 'asset.dart';

/// UI-side asset identifiers used across Home, Swap and other screens.
///
/// Kept separate from [Asset] (which is a pure data model with no Flutter
/// dependency) so that [SwapScreen] can import this without creating a
/// circular dependency through [HomeScreen].
enum AssetId { vavel, btc, eth, sol, ton }

extension AssetInfo on AssetId {
  Asset get asset => kAssets.firstWhere((a) => a.id == name);

  String get label => asset.name;
  String get ticker => asset.symbol;
  String? get geckoId => asset.geckoId;

  Color get color {
    switch (this) {
      case AssetId.vavel:
        return const Color(0xFF2979FF);
      case AssetId.btc:
        return const Color(0xFFF7931A);
      case AssetId.eth:
        return const Color(0xFF627EEA);
      case AssetId.sol:
        return const Color(0xFF9945FF);
      case AssetId.ton:
        return const Color(0xFF0098EA);
    }
  }

  IconData get icon {
    switch (this) {
      case AssetId.vavel:
        return Icons.token;
      case AssetId.btc:
        return Icons.currency_bitcoin;
      case AssetId.eth:
        return Icons.diamond_outlined;
      case AssetId.sol:
        return Icons.blur_circular;
      case AssetId.ton:
        return Icons.hub_outlined;
    }
  }
}
