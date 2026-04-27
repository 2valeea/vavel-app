import '../models/asset_id.dart';

/// Lowercase 0x-prefixed hex for EVM comparisons.
String _normalizeEvmHex(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  if (t.startsWith('0x') || t.startsWith('0X')) {
    return '0x${t.substring(2).toLowerCase()}';
  }
  return '0x${t.toLowerCase()}';
}

/// Normalizes a recipient string for comparisons (sent history, address book).
String normalizeRecipientAddress(AssetId assetId, String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  switch (assetId) {
    case AssetId.eth:
    case AssetId.vaval:
      return _normalizeEvmHex(t);
    case AssetId.sol:
    case AssetId.tiktok:
    case AssetId.ton:
      return t;
  }
}
