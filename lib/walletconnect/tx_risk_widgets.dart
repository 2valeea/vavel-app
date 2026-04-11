import 'package:flutter/material.dart';

import 'eth_tx_risk_analysis.dart';

Color txRiskColor(TxRiskLevel level) {
  return switch (level) {
    TxRiskLevel.info => const Color(0xFF42A5F5),
    TxRiskLevel.warning => const Color(0xFFFFB74D),
    TxRiskLevel.critical => const Color(0xFFFF5252),
  };
}

IconData txRiskIcon(TxRiskLevel level) {
  return switch (level) {
    TxRiskLevel.info => Icons.info_outline,
    TxRiskLevel.warning => Icons.warning_amber_rounded,
    TxRiskLevel.critical => Icons.gpp_maybe_rounded,
  };
}

/// Vertical list of pre-sign risk / info callouts.
class TxRiskSignalList extends StatelessWidget {
  const TxRiskSignalList({super.key, required this.signals});

  final List<TxRiskSignal> signals;

  @override
  Widget build(BuildContext context) {
    if (signals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < signals.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _TxRiskTile(signal: signals[i]),
        ],
      ],
    );
  }
}

class _TxRiskTile extends StatelessWidget {
  const _TxRiskTile({required this.signal});

  final TxRiskSignal signal;

  @override
  Widget build(BuildContext context) {
    final c = txRiskColor(signal.level);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(txRiskIcon(signal.level), color: c, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.title,
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  signal.detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
