import 'dart:convert';
import 'dart:typed_data';

import 'package:web3dart/web3dart.dart' show keccak256;

/// True if [raw] looks like an ENS name ending in `.eth` (ASCII, basic validation).
bool looksLikeEnsName(String raw) {
  final t = raw.trim().toLowerCase().replaceAll(RegExp(r'\.+$'), '');
  if (t.length <= 4 || !t.endsWith('.eth')) return false;
  return RegExp(
    r'^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*\.eth$',
  ).hasMatch(t);
}

/// Lowercase, strip trailing dots. Returns `null` if not [looksLikeEnsName].
String? normalizeEnsNameForResolution(String raw) {
  if (!looksLikeEnsName(raw)) return null;
  var s = raw.trim().toLowerCase();
  while (s.endsWith('.')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// ENS namehash (EIP-137). [name] must already be normalized (lowercase, no trailing dot).
///
/// Full Unicode normalization (ENSIP-15) is not applied here; ASCII `.eth` names match
/// on-chain resolution used by the app.
Uint8List ensNamehash(String name) {
  var node = Uint8List(32);
  if (name.isEmpty) return node;
  final labels =
      name.split('.').where((l) => l.isNotEmpty).toList(growable: false);
  for (var i = labels.length - 1; i >= 0; i--) {
    final labelHash = keccak256(Uint8List.fromList(utf8.encode(labels[i])));
    node = keccak256(Uint8List.fromList([...node, ...labelHash]));
  }
  return node;
}
