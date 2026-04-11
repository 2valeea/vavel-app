import 'eth_tx_risk_analysis.dart';

BigInt? _parseUint(dynamic v) {
  if (v == null) return null;
  if (v is BigInt) return v;
  if (v is int) return BigInt.from(v);
  if (v is num) return BigInt.from(v.toInt());
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  if (s.startsWith('0x') || s.startsWith('0X')) {
    return BigInt.tryParse(s.substring(2), radix: 16);
  }
  return BigInt.tryParse(s);
}

Map<String, dynamic>? _asMap(Object? o) {
  if (o is! Map) return null;
  return o.map((k, v) => MapEntry(k.toString(), v));
}

final _maxUint256 = (BigInt.one << 256) - BigInt.one;

bool _typesContain(Map<String, dynamic> root, String typeName) {
  final types = root['types'];
  if (types is! Map) return false;
  return types.containsKey(typeName);
}

/// Heuristic risk flags for EIP-712 payloads (WalletConnect `eth_signTypedData_v4`).
List<TxRiskSignal> analyzeTypedDataRisks(Map<String, dynamic> root) {
  final out = <TxRiskSignal>[];
  final primary = root['primaryType']?.toString() ?? '';
  final message = _asMap(root['message']) ?? {};

  if (primary == 'SafeTx' || (_typesContain(root, 'SafeTx') && message.containsKey('to'))) {
    final op = message['operation']?.toString() ?? '0';
    if (op == '1') {
      out.add(
        const TxRiskSignal(
          level: TxRiskLevel.critical,
          title: 'Safe: DELEGATECALL operation',
          detail:
              'Delegatecalls can change this Safe\'s logic in powerful ways. '
              'Only sign if you fully trust the target and the transaction preview.',
        ),
      );
    }
  }

  void checkPermitAmount(dynamic raw, String label) {
    final a = _parseUint(raw);
    if (a != null && a >= _maxUint256 - BigInt.from(1000)) {
      out.add(
        TxRiskSignal(
          level: TxRiskLevel.critical,
          title: 'Maximum $label amount',
          detail:
              'The signed value is effectively unlimited. A malicious spender could drain the token.',
        ),
      );
    }
  }

  if (primary == 'PermitSingle') {
    final details = _asMap(message['details']);
    checkPermitAmount(details?['amount'], 'Permit2 permit');
  }
  if (primary == 'PermitBatch') {
    final list = message['details'];
    if (list is List) {
      for (final item in list) {
        checkPermitAmount(_asMap(item)?['amount'], 'Permit2 batch entry');
      }
    }
  }
  if (primary == 'PermitTransferFrom') {
    final permitted = _asMap(message['permitted']);
    checkPermitAmount(
      permitted?['amount'] ?? message['amount'],
      'Permit2 transfer',
    );
  }

  if (primary == 'Permit' &&
      message.containsKey('spender') &&
      (message.containsKey('value') || message.containsKey('allowed'))) {
    checkPermitAmount(message['value'] ?? message['allowed'], 'EIP-2612 permit');
  }

  if (out.isEmpty) {
    out.add(
      const TxRiskSignal(
        level: TxRiskLevel.info,
        title: 'Review typed data carefully',
        detail:
            'Signatures can authorize token movements or on-chain actions. '
            'Expand technical details if anything looks different from the dApp.',
      ),
    );
  }

  return out;
}
