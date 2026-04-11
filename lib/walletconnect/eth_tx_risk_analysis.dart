import 'dart:typed_data';

import 'package:web3dart/web3dart.dart';

import 'wc_typed_data_preview.dart';

/// Severity for pre-sign risk callouts.
enum TxRiskLevel {
  info,
  warning,
  critical,
}

class TxRiskSignal {
  const TxRiskSignal({
    required this.level,
    required this.title,
    required this.detail,
  });

  final TxRiskLevel level;
  final String title;
  final String detail;
}

class EthTxDecodeSummary {
  const EthTxDecodeSummary({
    required this.functionLabel,
    required this.detailLines,
  });

  final String functionLabel;
  final List<String> detailLines;
}

final _maxUint256 = (BigInt.one << 256) - BigInt.one;

/// Known 4-byte selectors (lower hex, no 0x).
const _selTransfer = 'a9059cbb';
const _selApprove = '095ea7b3';
const _selTransferFrom = '23b872dd';
const _selSetApprovalForAll = 'a22cb465';

String? _hexData(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty || s == '0x') return null;
  return s;
}

BigInt? _parseWei(dynamic raw) {
  if (raw == null) return null;
  try {
    final s = raw.toString();
    if (s.isEmpty || s == '0x') return BigInt.zero;
    return BigInt.parse(strip0x(s), radix: 16);
  } catch (_) {
    return null;
  }
}

Uint8List? _hexToBytes(String hex) {
  var h = hex.trim();
  if (h.startsWith('0x') || h.startsWith('0X')) h = h.substring(2);
  if (h.length < 8) return null;
  if (h.length % 2 != 0) return null;
  try {
    final out = Uint8List(h.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  } catch (_) {
    return null;
  }
}

String? _readAddress(Uint8List word32) {
  if (word32.length < 32) return null;
  final addrBytes = word32.sublist(12, 32);
  return bytesToHex(addrBytes, include0x: true);
}

BigInt? _readUint256(Uint8List word32) {
  if (word32.length < 32) return null;
  var r = BigInt.zero;
  for (var i = 0; i < 32; i++) {
    r = (r << 8) + BigInt.from(word32[i]);
  }
  return r;
}

/// Human-readable decode + risk signals for WalletConnect `eth_sendTransaction` payloads.
({EthTxDecodeSummary? decode, List<TxRiskSignal> risks}) analyzeEthereumTxRisks({
  required Map<String, dynamic> transaction,
}) {
  final risks = <TxRiskSignal>[];
  final to = transaction['to']?.toString();
  final valueWei = _parseWei(transaction['value']);
  final dataHex = _hexData(transaction['data']);
  final dataBytes =
      dataHex != null ? _hexToBytes(strip0x(dataHex)) : null;

  if (to != null && to.isNotEmpty) {
    final toLower = to.toLowerCase();
    if (!toLower.startsWith('0x') || toLower.length != 42) {
      risks.add(
        const TxRiskSignal(
          level: TxRiskLevel.warning,
          title: 'Unusual recipient',
          detail: 'The "to" field is not a standard 20-byte hex address.',
        ),
      );
    }
  }

  final hasValue = valueWei != null && valueWei > BigInt.zero;
  final hasData = dataBytes != null && dataBytes.isNotEmpty;

  if (hasValue && hasData) {
    final v = valueWei;
    risks.add(
      TxRiskSignal(
        level: TxRiskLevel.warning,
        title: 'ETH sent with contract call',
        detail:
            'You are sending ${v / BigInt.from(10).pow(18)} ETH together with calldata. '
            'Many scams use this pattern. Confirm the dApp and contract are trusted.',
      ),
    );
  }

  if (dataBytes == null || dataBytes.length < 4) {
    if (hasValue && (to == null || to.isEmpty)) {
      risks.add(
        const TxRiskSignal(
          level: TxRiskLevel.critical,
          title: 'Contract creation with ETH',
          detail:
              'This transaction sends ETH while creating a contract. Only proceed if you fully understand the bytecode.',
        ),
      );
    }
    final summary = EthTxDecodeSummary(
      functionLabel: 'Simple transfer',
      detailLines: [
        if (to != null) 'To: ${shortHexAddress(to)}',
        'Value: ${_formatEth(valueWei ?? BigInt.zero)}',
        'Calldata: none',
      ],
    );
    if (hasValue && valueWei > BigInt.from(10).pow(21)) {
      risks.add(
        TxRiskSignal(
          level: TxRiskLevel.info,
          title: 'Large ETH transfer',
          detail:
              'You are sending ${_formatEth(valueWei)}. Double-check the recipient address.',
        ),
      );
    }
    return (decode: summary, risks: risks);
  }

  final selector =
      bytesToHex(dataBytes.sublist(0, 4), include0x: false).toLowerCase();
  final body = dataBytes.length > 4
      ? dataBytes.sublist(4)
      : Uint8List(0);

  EthTxDecodeSummary? summary;

  switch (selector) {
    case _selTransfer:
      if (body.length >= 64) {
        final toTok = _readAddress(body.sublist(0, 32));
        final amt = _readUint256(body.sublist(32, 64));
        summary = EthTxDecodeSummary(
          functionLabel: 'ERC-20 transfer(address,uint256)',
          detailLines: [
            'Token contract: ${shortHexAddress(to)}',
            'Recipient: ${shortHexAddress(toTok)}',
            'Amount (raw): ${amt ?? '—'} smallest units',
          ],
        );
      } else {
        summary = EthTxDecodeSummary(
          functionLabel: 'ERC-20 transfer (malformed args)',
          detailLines: [
            'Token contract: ${shortHexAddress(to)}',
            'Calldata appears truncated.',
          ],
        );
      }
      break;
    case _selApprove:
      if (body.length >= 64) {
        final spender = _readAddress(body.sublist(0, 32));
        final amt = _readUint256(body.sublist(32, 64));
        summary = EthTxDecodeSummary(
          functionLabel: 'ERC-20 approve(address,uint256)',
          detailLines: [
            'Token contract: ${shortHexAddress(to)}',
            'Spender: ${shortHexAddress(spender)}',
            'Allowance (raw): ${amt ?? '—'}',
          ],
        );
        if (amt != null && amt >= _maxUint256 - BigInt.from(1000)) {
          risks.add(
            const TxRiskSignal(
              level: TxRiskLevel.critical,
              title: 'Unlimited (or max) token approval',
              detail:
                  'The spender may be able to move all of this token from your wallet. '
                  'Common in legitimate DeFi, but also in drain scams. Verify the spender contract.',
            ),
          );
        } else if (amt != null && amt > BigInt.zero) {
          risks.add(
            const TxRiskSignal(
              level: TxRiskLevel.warning,
              title: 'Token allowance increase',
              detail:
                  'You are granting an on-chain allowance. Malicious spenders can move tokens up to the approved amount.',
            ),
          );
        }
      } else {
        summary = EthTxDecodeSummary(
          functionLabel: 'ERC-20 approve (malformed args)',
          detailLines: ['Token contract: ${shortHexAddress(to)}'],
        );
      }
      break;
    case _selTransferFrom:
      if (body.length >= 96) {
        final from = _readAddress(body.sublist(0, 32));
        final recipient = _readAddress(body.sublist(32, 64));
        final amt = _readUint256(body.sublist(64, 96));
        summary = EthTxDecodeSummary(
          functionLabel: 'ERC-20 transferFrom(address,address,uint256)',
          detailLines: [
            'Token contract: ${shortHexAddress(to)}',
            'From: ${shortHexAddress(from)}',
            'To: ${shortHexAddress(recipient)}',
            'Amount (raw): ${amt ?? '—'}',
          ],
        );
        risks.add(
          const TxRiskSignal(
            level: TxRiskLevel.warning,
            title: 'Moving tokens via allowance',
            detail:
                'transferFrom pulls tokens using a prior allowance. Confirm you expect this movement.',
          ),
        );
      } else {
        summary = EthTxDecodeSummary(
          functionLabel: 'ERC-20 transferFrom (malformed args)',
          detailLines: ['Token contract: ${shortHexAddress(to)}'],
        );
      }
      break;
    case _selSetApprovalForAll:
      if (body.length >= 64) {
        final op = _readAddress(body.sublist(0, 32));
        final approved = body[63] != 0;
        summary = EthTxDecodeSummary(
          functionLabel: 'ERC-721/1155 setApprovalForAll',
          detailLines: [
            'Contract: ${shortHexAddress(to)}',
            'Operator: ${shortHexAddress(op)}',
            'Approved for all: $approved',
          ],
        );
        if (approved) {
          risks.add(
            const TxRiskSignal(
              level: TxRiskLevel.critical,
              title: 'NFT / multi-token operator approval',
              detail:
                  'The operator may be able to move all NFTs (or token IDs) from this collection. '
                  'Only approve operators you trust.',
            ),
          );
        }
      } else {
        summary = EthTxDecodeSummary(
          functionLabel: 'setApprovalForAll (malformed args)',
          detailLines: ['Contract: ${shortHexAddress(to)}'],
        );
      }
      break;
    default:
      summary = EthTxDecodeSummary(
        functionLabel: 'Contract call (unknown selector)',
        detailLines: [
          'To: ${shortHexAddress(to)}',
          'Selector: 0x$selector',
          'Calldata size: ${dataBytes.length} bytes',
        ],
      );
      risks.add(
        const TxRiskSignal(
          level: TxRiskLevel.warning,
          title: 'Unrecognized contract method',
          detail:
              'This wallet could not decode the function. Review the dApp UI and only confirm if you trust it.',
        ),
      );
      if (dataBytes.length > 500) {
        risks.add(
          const TxRiskSignal(
            level: TxRiskLevel.info,
            title: 'Large calldata',
            detail:
                'Complex interactions are harder to reason about. When in doubt, reject.',
          ),
        );
      }
  }

  return (decode: summary, risks: risks);
}

String _formatEth(BigInt wei) {
  if (wei == BigInt.zero) return '0 ETH';
  final eth = wei / BigInt.from(10).pow(18);
  return '$eth ETH';
}
