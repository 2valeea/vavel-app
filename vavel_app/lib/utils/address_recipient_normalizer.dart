import '../models/asset_id.dart';
import 'ens_utils.dart';

/// Normalizes a recipient string for comparisons (sent history, address book).
///
/// For ETH / VAVEL, `.eth` names are stored in normalized lowercase form
/// (labels); resolution to `0x` happens at send time via ENS.
String normalizeRecipientAddress(AssetId assetId, String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  switch (assetId) {
    case AssetId.eth:
    case AssetId.vavel:
      final ens = normalizeEnsNameForResolution(t);
      if (ens != null) return ens;
      var h = t.startsWith('0x') || t.startsWith('0X') ? t.substring(2) : t;
      if (h.length == 40 && RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(h)) {
        return '0x${h.toLowerCase()}';
      }
      return t.toLowerCase();
    case AssetId.btc:
    case AssetId.sol:
    case AssetId.tiktok:
    case AssetId.ton:
      return t;
  }
}
