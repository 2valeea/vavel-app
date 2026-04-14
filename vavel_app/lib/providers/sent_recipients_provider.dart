import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset_id.dart';
import '../utils/address_recipient_normalizer.dart';

/// Tracks recipient addresses the user has successfully sent to (per asset).
class SentRecipientsNotifier extends AsyncNotifier<Map<String, List<String>>> {
  static const _prefsKey = 'sent_recipients_v1';

  @override
  Future<Map<String, List<String>>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          (v as List).whereType<String>().toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<bool> hasSentTo(AssetId assetId, String rawAddress) async {
    final norm = normalizeRecipientAddress(assetId, rawAddress);
    final map = await future;
    final list = map[assetId.name] ?? const [];
    return list.contains(norm);
  }

  Future<void> markSent(AssetId assetId, String rawAddress) async {
    final norm = normalizeRecipientAddress(assetId, rawAddress);
    if (norm.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final prev = await future;
    final current = <String, List<String>>{};
    for (final e in prev.entries) {
      current[e.key] = List<String>.from(e.value);
    }
    final key = assetId.name;
    final list = List<String>.from(current[key] ?? []);
    if (!list.contains(norm)) {
      list.add(norm);
      current[key] = list;
    }
    await prefs.setString(_prefsKey, jsonEncode(current));
    state = AsyncData(current);
  }
}

final sentRecipientsProvider =
    AsyncNotifierProvider<SentRecipientsNotifier, Map<String, List<String>>>(
  SentRecipientsNotifier.new,
);
