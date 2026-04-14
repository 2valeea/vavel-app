import 'eth_tx_risk_analysis.dart';

/// Heuristics for WalletConnect `personal_sign` preview text.
List<TxRiskSignal> analyzePersonalMessageRisks(String preview) {
  final t = preview.trim();
  final looksLikeHexPayload = RegExp(r'^0x[0-9a-fA-F]{64,}$').hasMatch(t);
  if (looksLikeHexPayload) {
    return [
      const TxRiskSignal(
        level: TxRiskLevel.warning,
        title: 'Opaque binary message',
        detail:
            'This is a raw hex payload, not plain text. Malicious sites can hide '
            'sign-in requests or permit data here. Only sign if you trust this dApp.',
      ),
    ];
  }
  return [
    const TxRiskSignal(
      level: TxRiskLevel.info,
      title: 'Review the full message',
      detail:
          'Signatures can prove ownership or authorize off-chain actions. '
          'Reject if anything differs from what the site showed you.',
    ),
  ];
}
