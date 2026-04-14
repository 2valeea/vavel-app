import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../walletconnect/wc_activity_entry.dart';

/// Persisted WalletConnect activity (newest first). Capped for storage size.
class WcActivityLogNotifier extends AsyncNotifier<List<WcActivityEntry>> {
  static const _prefsKey = 'wc_activity_log_v1';
  static const _maxEntries = 200;

  @override
  Future<List<WcActivityEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <WcActivityEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final e = WcActivityEntry.tryFromJson(Map<String, dynamic>.from(item));
        if (e != null) out.add(e);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(WcActivityEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final merged = [entry, ...await future].take(_maxEntries).toList();
    await prefs.setString(
      _prefsKey,
      jsonEncode(merged.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(merged);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = const AsyncData([]);
  }
}

final wcActivityLogProvider =
    AsyncNotifierProvider<WcActivityLogNotifier, List<WcActivityEntry>>(
  WcActivityLogNotifier.new,
);
