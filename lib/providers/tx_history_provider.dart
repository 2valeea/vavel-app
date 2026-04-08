import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kHistoryKey = 'tx_history';
const _storage = FlutterSecureStorage();

/// A single recorded transaction.
class TxRecord {
  final String id;
  final String asset;
  final String to;
  final double amount;
  final String? txHash;
  final DateTime timestamp;

  const TxRecord({
    required this.id,
    required this.asset,
    required this.to,
    required this.amount,
    this.txHash,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'asset': asset,
        'to': to,
        'amount': amount,
        'txHash': txHash,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TxRecord.fromJson(Map<String, dynamic> j) => TxRecord(
        id: j['id'] as String,
        asset: j['asset'] as String,
        to: j['to'] as String,
        amount: (j['amount'] as num).toDouble(),
        txHash: j['txHash'] as String?,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

/// Riverpod notifier that persists transaction history in secure storage.
final txHistoryProvider =
    StateNotifierProvider<TxHistoryNotifier, List<TxRecord>>(
        (ref) => TxHistoryNotifier());

class TxHistoryNotifier extends StateNotifier<List<TxRecord>> {
  TxHistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _kHistoryKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => TxRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {
      // Corrupt data — reset silently.
      await _storage.delete(key: _kHistoryKey);
    }
  }

  Future<void> add(TxRecord record) async {
    final updated = [record, ...state];
    state = updated;
    await _storage.write(
        key: _kHistoryKey,
        value: jsonEncode(updated.map((r) => r.toJson()).toList()));
  }

  Future<void> clear() async {
    state = [];
    await _storage.delete(key: _kHistoryKey);
  }
}
