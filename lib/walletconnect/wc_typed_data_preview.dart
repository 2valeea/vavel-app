import 'dart:convert';

/// High-level classification for EIP-712 previews.
enum TypedDataPreviewKind {
  permit2,
  permitEip2612,
  safeTx,
  safeMessage,
  generic,
}

/// Human-readable summary of typed data for confirmation UIs.
class TypedDataHumanPreview {
  const TypedDataHumanPreview({
    required this.kind,
    required this.headline,
    required this.bullets,
    this.securityNote,
  });

  final TypedDataPreviewKind kind;
  final String headline;
  final List<String> bullets;

  /// Extra caution when interpretation is heuristic.
  final String? securityNote;
}

String shortHexAddress(String? addr, {int prefix = 8, int suffix = 6}) {
  if (addr == null || addr.isEmpty) return '—';
  final a = addr.trim();
  if (!a.startsWith('0x') || a.length < 12) return a;
  if (a.length <= prefix + suffix + 1) return a;
  return '${a.substring(0, prefix)}…${a.substring(a.length - suffix)}';
}

/// Returns a lowercase `0x` + 40 hex key, or `null` if [raw] is not a 20-byte address.
String? normalizeErc20AddressKey(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.length != 42 || !t.startsWith('0x')) return null;
  final hex = t.substring(2);
  if (!RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(hex)) return null;
  return '0x${hex.toLowerCase()}';
}

/// ERC-20 contract addresses that may need a [decimals] RPC call for Permit2 / EIP-2612 previews.
List<String> erc20AddressesForTypedDataPreview(Map<String, dynamic> root) {
  final seen = <String>{};
  void add(String? raw) {
    final k = normalizeErc20AddressKey(raw);
    if (k != null) seen.add(k);
  }

  final primary = root['primaryType']?.toString() ?? '';
  final message = _asStringKeyedMap(root['message']) ?? {};
  final domain = _asStringKeyedMap(root['domain']);

  switch (primary) {
    case 'PermitSingle':
      add(_asStringKeyedMap(message['details'])?['token']?.toString());
    case 'PermitBatch':
      final detailsList = message['details'];
      if (detailsList is List) {
        for (final item in detailsList) {
          add(_asStringKeyedMap(item)?['token']?.toString());
        }
      }
    case 'PermitTransferFrom':
      add(_asStringKeyedMap(message['permitted'])?['token']?.toString());
      add(message['token']?.toString());
    case 'Permit':
      add(domain?['verifyingContract']?.toString());
    default:
      break;
  }
  return seen.toList();
}

String _bigIntishToString(dynamic v) {
  if (v == null) return '—';
  if (v is BigInt) return v.toString();
  if (v is num) return v.toString();
  return v.toString();
}

BigInt? _tryParseUint(dynamic v) {
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

/// Formats a token smallest-unit amount using on-chain [decimals], for UI previews.
String formatTokenAmountForPreview(
  dynamic raw,
  int? decimals, {
  int maxFractionDigits = 8,
}) {
  final amount = _tryParseUint(raw);
  if (amount == null) return _bigIntishToString(raw);
  if (decimals == null || decimals < 0 || decimals > 36) {
    return '${amount.toString()} smallest units (token decimals unavailable)';
  }
  if (decimals == 0) {
    return '$amount tokens (0 decimals)';
  }
  final divisor = BigInt.from(10).pow(decimals);
  final neg = amount < BigInt.zero;
  final a = neg ? -amount : amount;
  final whole = a ~/ divisor;
  var fracDigits = (a % divisor).toString().padLeft(decimals, '0');
  fracDigits = fracDigits.replaceFirst(RegExp(r'0+$'), '');
  if (fracDigits.length > maxFractionDigits) {
    fracDigits = fracDigits.substring(0, maxFractionDigits).replaceFirst(RegExp(r'0+$'), '');
  }
  final sign = neg ? '-' : '';
  if (fracDigits.isEmpty) {
    return '$sign$whole tokens ($decimals on-chain decimals; raw $a smallest units)';
  }
  return '$sign$whole.$fracDigits tokens ($decimals decimals; raw $a smallest units)';
}

String? _formatWeiEth(dynamic wei) {
  final w = _tryParseUint(wei);
  if (w == null) return null;
  if (w == BigInt.zero) return '0 ETH';
  final eth = w / BigInt.from(10).pow(18);
  return '$eth ETH';
}

String? _formatUnix(dynamic seconds) {
  final s = _tryParseUint(seconds);
  if (s == null) return null;
  if (s > BigInt.from(1) << 62) return seconds.toString();
  final dt = DateTime.fromMillisecondsSinceEpoch(s.toInt() * 1000, isUtc: true);
  return '${dt.toIso8601String()} UTC';
}

Map<String, dynamic>? _asStringKeyedMap(Object? o) {
  if (o is! Map) return null;
  return o.map((k, v) => MapEntry(k.toString(), v));
}

bool _domainNameIsPermit2(Map<String, dynamic>? domain) {
  final n = domain?['name']?.toString().toLowerCase() ?? '';
  return n == 'permit2';
}

bool _typesContain(Map<String, dynamic> root, String typeName) {
  final types = root['types'];
  if (types is! Map) return false;
  return types.containsKey(typeName);
}

int? _decimalsForToken(
  String? token,
  Map<String, int> tokenDecimalsByLowerAddress,
) {
  final k = normalizeErc20AddressKey(token);
  if (k == null) return null;
  return tokenDecimalsByLowerAddress[k];
}

TypedDataHumanPreview buildTypedDataHumanPreview(
  Map<String, dynamic> root, {
  Map<String, int> tokenDecimalsByLowerAddress = const {},
}) {
  final primary = root['primaryType']?.toString() ?? '';
  final domain = _asStringKeyedMap(root['domain']);
  final message = _asStringKeyedMap(root['message']) ?? {};
  final permit2Domain = _domainNameIsPermit2(domain);

  // ── Gnosis Safe: typed Safe transaction ───────────────────────────────────
  if (primary == 'SafeTx' || (_typesContain(root, 'SafeTx') && message.containsKey('to'))) {
    final to = message['to']?.toString();
    final value = _formatWeiEth(message['value']) ?? _bigIntishToString(message['value']);
    final op = message['operation']?.toString() ?? '0';
    final opLabel = switch (op) {
      '0' => 'CALL',
      '1' => 'DELEGATECALL',
      _ => 'operation $op',
    };
    final data = message['data']?.toString() ?? '0x';
    final dataLen = data == '0x' ? 0 : (data.length ~/ 2) - 1;
    final nonce = message['nonce']?.toString() ?? '—';
    return TypedDataHumanPreview(
      kind: TypedDataPreviewKind.safeTx,
      headline: 'Gnosis Safe transaction',
      bullets: [
        'To: ${shortHexAddress(to)}',
        'Value: $value',
        'Calldata: $dataLen bytes ($opLabel)',
        'Safe nonce: $nonce',
      ],
      securityNote:
          'This authorizes an on-chain execution from the Safe. Verify recipient, value, and calldata match what you expect.',
    );
  }

  // ── Gnosis Safe: off-chain message ───────────────────────────────────────
  if (primary == 'SafeMessage' || (_typesContain(root, 'SafeMessage') && message.containsKey('message'))) {
    final raw = message['message'];
    String preview;
    if (raw is String) {
      preview = raw.length > 280 ? '${raw.substring(0, 280)}…' : raw;
    } else {
      preview = const JsonEncoder.withIndent('  ').convert(raw);
      if (preview.length > 400) preview = '${preview.substring(0, 400)}…';
    }
    return TypedDataHumanPreview(
      kind: TypedDataPreviewKind.safeMessage,
      headline: 'Gnosis Safe message',
      bullets: [
        'You are signing an off-chain message for a Safe.',
        'Content preview:',
        preview,
      ],
      securityNote: 'Confirm this message matches what the app showed you.',
    );
  }

  // ── Uniswap Permit2 (explicit primary types or Permit2 domain) ───────────
  if (primary == 'PermitSingle' ||
      primary == 'PermitBatch' ||
      primary == 'PermitTransferFrom' ||
      permit2Domain) {
    if (primary == 'PermitSingle') {
      final details = _asStringKeyedMap(message['details']);
      final token = details?['token']?.toString();
      final amount = details?['amount'];
      final exp = details?['expiration'];
      final nonce = details?['nonce'];
      final spender = message['spender']?.toString();
      final deadline = message['sigDeadline'] ?? message['deadline'];
      final dec = _decimalsForToken(token, tokenDecimalsByLowerAddress);
      return TypedDataHumanPreview(
        kind: TypedDataPreviewKind.permit2,
        headline: 'Permit2 allowance (single token)',
        bullets: [
          'Token: ${shortHexAddress(token)}',
          'Amount: ${formatTokenAmountForPreview(amount, dec)}',
          'Spender: ${shortHexAddress(spender)}',
          if (exp != null) 'Details expiration (uint): ${_bigIntishToString(exp)}',
          if (nonce != null) 'Permit2 nonce: ${_bigIntishToString(nonce)}',
          if (deadline != null) 'Signature deadline: ${_formatUnix(deadline) ?? deadline}',
        ],
        securityNote:
            'This lets the spender move up to the shown amount from your wallet via Permit2. '
            'Verify the token, spender, and limits carefully.',
      );
    }
    if (primary == 'PermitBatch') {
      final detailsList = message['details'];
      final count = detailsList is List ? detailsList.length : 0;
      final spender = message['spender']?.toString();
      final deadline = message['sigDeadline'];
      final bullets = <String>[
        'Token entries: $count',
        if (spender != null) 'Spender: ${shortHexAddress(spender)}',
        if (deadline != null) 'Signature deadline: ${_formatUnix(deadline) ?? deadline}',
      ];
      if (detailsList is List) {
        final show = detailsList.length > 6 ? 6 : detailsList.length;
        for (var i = 0; i < show; i++) {
          final det = _asStringKeyedMap(detailsList[i]);
          final tok = det?['token']?.toString();
          final amt = det?['amount'];
          final dec = _decimalsForToken(tok, tokenDecimalsByLowerAddress);
          bullets.add(
            '${i + 1}. ${shortHexAddress(tok)} — ${formatTokenAmountForPreview(amt, dec)}',
          );
        }
        if (detailsList.length > show) {
          bullets.add('… and ${detailsList.length - show} more (see technical details)');
        }
      }
      return TypedDataHumanPreview(
        kind: TypedDataPreviewKind.permit2,
        headline: 'Permit2 allowance (batch)',
        bullets: bullets,
        securityNote: 'Review each token entry in technical details before signing.',
      );
    }
    if (primary == 'PermitTransferFrom') {
      final permitted = _asStringKeyedMap(message['permitted']);
      final token = permitted?['token']?.toString() ?? message['token']?.toString();
      final amount = permitted?['amount'] ?? message['amount'];
      final spender = message['spender']?.toString();
      final nonce = message['nonce'];
      final deadline = message['deadline'];
      final dec = _decimalsForToken(token, tokenDecimalsByLowerAddress);
      return TypedDataHumanPreview(
        kind: TypedDataPreviewKind.permit2,
        headline: 'Permit2 transfer permit',
        bullets: [
          'Token: ${shortHexAddress(token)}',
          'Amount: ${formatTokenAmountForPreview(amount, dec)}',
          if (spender != null) 'Spender: ${shortHexAddress(spender)}',
          if (nonce != null) 'Nonce: ${_bigIntishToString(nonce)}',
          if (deadline != null) 'Deadline: ${_formatUnix(deadline) ?? deadline}',
        ],
        securityNote:
            'This authorizes a specific Permit2 transfer shape. Confirm token, amount, and spender.',
      );
    }
    return TypedDataHumanPreview(
      kind: TypedDataPreviewKind.permit2,
      headline: 'Permit2 typed data ($primary)',
      bullets: [
        'This request uses the Permit2 contract pattern.',
        'Use technical details to inspect all fields before signing.',
      ],
      securityNote: 'Permit2 layouts vary; always verify token, spender, amounts, and deadlines.',
    );
  }

  // ── ERC-20 EIP-2612 Permit (not Permit2) ──────────────────────────────────
  if (primary == 'Permit' &&
      message.containsKey('spender') &&
      (message.containsKey('value') || message.containsKey('allowed')) &&
      (message.containsKey('deadline') || message.containsKey('expiry'))) {
    final owner = message['owner']?.toString() ?? message['holder']?.toString();
    final spender = message['spender']?.toString();
    final value = message['value'] ?? message['allowed'];
    final nonce = message['nonce'];
    final deadline = message['deadline'] ?? message['expiry'];
    final token = domain?['verifyingContract']?.toString();
    final dec = _decimalsForToken(token, tokenDecimalsByLowerAddress);
    return TypedDataHumanPreview(
      kind: TypedDataPreviewKind.permitEip2612,
      headline: 'Token permit (EIP-2612)',
      bullets: [
        'Token contract: ${shortHexAddress(token)}',
        if (owner != null) 'Owner: ${shortHexAddress(owner)}',
        if (spender != null) 'Spender: ${shortHexAddress(spender)}',
        'Allowance: ${formatTokenAmountForPreview(value, dec)}',
        if (nonce != null) 'Nonce: ${_bigIntishToString(nonce)}',
        if (deadline != null) 'Deadline: ${_formatUnix(deadline) ?? deadline}',
      ],
      securityNote:
          'This increases the spender\'s allowance on the token contract up to the signed amount.',
    );
  }

  // ── Generic ──────────────────────────────────────────────────────────────
  return TypedDataHumanPreview(
    kind: TypedDataPreviewKind.generic,
    headline: 'Typed data ($primary)',
    bullets: [
      'This is custom EIP-712 structured data.',
      'Expand "Technical details" to review domain and message fields in full.',
    ],
    securityNote: 'Only sign if you understand every field or you trust this application.',
  );
}
