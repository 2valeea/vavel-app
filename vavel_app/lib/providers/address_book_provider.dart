import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_book_entry.dart';
import '../models/asset_id.dart';
import '../utils/address_recipient_normalizer.dart';
import '../utils/ens_utils.dart';
import 'wallet_provider.dart';

class AddressBookNotifier extends AsyncNotifier<List<AddressBookEntry>> {
  static const _prefsKey = 'address_book_v1';
  static const _maxEntries = 500;

  @override
  Future<List<AddressBookEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      final out = <AddressBookEntry>[];
      for (final item in list) {
        if (item is! Map) continue;
        final e = AddressBookEntry.tryFromJson(Map<String, dynamic>.from(item));
        if (e != null) out.add(e);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<AddressBookEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  Future<void> add({
    required String label,
    required String address,
    required AssetId assetId,
  }) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    final normalized =
        normalizeRecipientAddress(assetId, trimmed);
    if ((assetId == AssetId.eth || assetId == AssetId.vavel) &&
        looksLikeEnsName(normalized)) {
      await ref.read(walletServiceProvider).resolveEthereumRecipient(normalized);
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = AddressBookEntry(
      id: id,
      label: label.trim().isEmpty ? 'Contact' : label.trim(),
      address: normalized,
      assetKey: assetId.name,
    );
    final next = [entry, ...await future].take(_maxEntries).toList();
    await _persist(next);
  }

  Future<void> remove(String id) async {
    final next = (await future).where((e) => e.id != id).toList();
    await _persist(next);
  }

  Future<void> editEntry({
    required String id,
    required String label,
    required String address,
    required AssetId assetId,
  }) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    final normalized = normalizeRecipientAddress(assetId, trimmed);
    if ((assetId == AssetId.eth || assetId == AssetId.vavel) &&
        looksLikeEnsName(normalized)) {
      await ref.read(walletServiceProvider).resolveEthereumRecipient(normalized);
    }
    final list = await future;
    final idx = list.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final next = List<AddressBookEntry>.from(list);
    next[idx] = AddressBookEntry(
      id: id,
      label: label.trim().isEmpty ? 'Contact' : label.trim(),
      address: normalized,
      assetKey: assetId.name,
    );
    await _persist(next);
  }
}

final addressBookProvider =
    AsyncNotifierProvider<AddressBookNotifier, List<AddressBookEntry>>(
  AddressBookNotifier.new,
);

List<AddressBookEntry> addressBookForAsset(List<AddressBookEntry> all, AssetId id) {
  return all.where((e) => e.assetKey == id.name).toList();
}
