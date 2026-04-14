import 'dart:convert';
import 'dart:typed_data';

import 'package:web3dart/web3dart.dart';

/// Result of parsing WalletConnect `personal_sign` parameters.
class WalletConnectPersonalParseResult {
  final List<int> payload;
  final String preview;
  final String? declaredAddress;

  const WalletConnectPersonalParseResult({
    required this.payload,
    required this.preview,
    required this.declaredAddress,
  });
}

/// Result of parsing WalletConnect `eth_signTypedData_v4` parameters.
class WalletConnectTypedDataV4ParseResult {
  /// JSON string passed to the EIP-712 signer (must match what the dApp intended).
  final String jsonForSigning;

  /// Decoded root object (`types`, `domain`, `primaryType`, `message`) for UI.
  final Map<String, dynamic> rootMap;

  const WalletConnectTypedDataV4ParseResult({
    required this.jsonForSigning,
    required this.rootMap,
  });
}

bool _looksEthAddress(String s) {
  final t = s.trim();
  return t.startsWith('0x') && t.length == 42;
}

/// Parses `personal_sign` RPC params: `[message, address]` (order may vary).
WalletConnectPersonalParseResult parseWalletConnectPersonalSign(
  dynamic params,
  String walletAddress,
) {
  if (params is! List || params.length < 2) {
    throw const FormatException('personal_sign expects [message, address]');
  }
  final a = params[0].toString();
  final b = params[1].toString();
  final wal = walletAddress.toLowerCase();

  String msgField;
  String? addrField;
  if (_looksEthAddress(a) && _looksEthAddress(b)) {
    if (a.toLowerCase() == wal) {
      addrField = a;
      msgField = b;
    } else if (b.toLowerCase() == wal) {
      addrField = b;
      msgField = a;
    } else {
      msgField = a;
      addrField = b;
    }
  } else if (_looksEthAddress(a)) {
    addrField = a;
    msgField = b;
  } else if (_looksEthAddress(b)) {
    addrField = b;
    msgField = a;
  } else {
    msgField = a;
    addrField = null;
  }

  if (addrField != null && addrField.toLowerCase() != wal) {
    throw StateError(
      'The requested signer address does not match this wallet.',
    );
  }

  final List<int> payload;
  if (msgField.startsWith('0x')) {
    payload = Uint8List.fromList(hexToBytes(msgField));
  } else {
    payload = utf8.encode(msgField);
  }

  String preview;
  try {
    preview = utf8.decode(payload);
    if (preview.length > 2000) {
      preview = '${preview.substring(0, 2000)}…';
    }
  } catch (_) {
    preview = bytesToHex(Uint8List.fromList(payload), include0x: true);
    if (preview.length > 2000) {
      preview = '${preview.substring(0, 2000)}…';
    }
  }

  return WalletConnectPersonalParseResult(
    payload: payload,
    preview: preview,
    declaredAddress: addrField,
  );
}

/// Reads [domain.chainId] from a typed-data root map when present.
int? readEip712DomainChainId(Map<String, dynamic> root) {
  final domain = root['domain'];
  if (domain is! Map) return null;
  final m = Map<String, dynamic>.from(domain);
  final raw = m['chainId'];
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is BigInt) return raw.toInt();
  if (raw is String) {
    final s = raw.trim();
    if (s.startsWith('0x') || s.startsWith('0X')) {
      return int.parse(s.substring(2), radix: 16);
    }
    return int.parse(s);
  }
  return null;
}

Map<String, dynamic> _typedDataObjectFromSecondParam(dynamic second) {
  if (second is String) {
    final decoded = jsonDecode(second);
    if (decoded is! Map) {
      throw const FormatException('eth_signTypedData_v4 JSON must be an object');
    }
    return Map<String, dynamic>.from(decoded);
  }
  if (second is Map) {
    return Map<String, dynamic>.from(second);
  }
  throw const FormatException(
    'eth_signTypedData_v4 typed data must be a JSON string or object',
  );
}

/// Parses `eth_signTypedData_v4` params: `[address, typedData]` (address may be first or second).
///
/// When the typed data [domain] includes [chainId], it must equal [expectedWalletChainId]
/// so users cannot be tricked into signing for another network.
WalletConnectTypedDataV4ParseResult parseWalletConnectEthSignTypedDataV4(
  dynamic params,
  String walletAddress,
  int expectedWalletChainId,
) {
  if (params is! List || params.length < 2) {
    throw const FormatException(
      'eth_signTypedData_v4 expects [address, typedData]',
    );
  }
  final first = params[0];
  final second = params[1];
  final wal = walletAddress.toLowerCase();

  late final String addressField;
  late final dynamic typedRaw;

  final fStr = first.toString();
  final sStr = second.toString();
  if (_looksEthAddress(fStr) && !_looksEthAddress(sStr)) {
    addressField = fStr.trim();
    typedRaw = second;
  } else if (_looksEthAddress(sStr) && ! _looksEthAddress(fStr)) {
    addressField = sStr.trim();
    typedRaw = first;
  } else if (_looksEthAddress(fStr) && _looksEthAddress(sStr)) {
    if (fStr.toLowerCase() == wal) {
      addressField = fStr.trim();
      typedRaw = second;
    } else if (sStr.toLowerCase() == wal) {
      addressField = sStr.trim();
      typedRaw = first;
    } else {
      throw StateError(
        'Neither parameter matches this wallet address for typed data signing.',
      );
    }
  } else {
    throw const FormatException(
      'Could not determine signer address for eth_signTypedData_v4',
    );
  }

  if (addressField.toLowerCase() != wal) {
    throw StateError(
      'The requested signer address does not match this wallet.',
    );
  }

  final rootMap = _typedDataObjectFromSecondParam(typedRaw);
  if (rootMap['types'] == null ||
      rootMap['primaryType'] == null ||
      rootMap['message'] == null) {
    throw const FormatException(
      'Typed data must include types, primaryType, and message',
    );
  }

  final domainChain = readEip712DomainChainId(rootMap);
  if (domainChain != null && domainChain != expectedWalletChainId) {
    throw StateError(
      'Typed data domain chainId ($domainChain) does not match this wallet '
      '(chain ID $expectedWalletChainId).',
    );
  }

  final jsonForSigning = typedRaw is String
      ? typedRaw.trim()
      : jsonEncode(rootMap);

  return WalletConnectTypedDataV4ParseResult(
    jsonForSigning: jsonForSigning,
    rootMap: rootMap,
  );
}
