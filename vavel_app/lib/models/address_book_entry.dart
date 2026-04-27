class AddressBookEntry {
  const AddressBookEntry({
    required this.id,
    required this.label,
    required this.address,
    required this.assetKey,
  });

  final String id;
  final String label;
  final String address;
  /// Matches [AssetId.name] this contact applies to (e.g. sol, ton).
  final String assetKey;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'assetKey': assetKey,
      };

  static AddressBookEntry? tryFromJson(Map<String, dynamic> j) {
    try {
      return AddressBookEntry(
        id: j['id'] as String,
        label: j['label'] as String,
        address: j['address'] as String,
        assetKey: j['assetKey'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
