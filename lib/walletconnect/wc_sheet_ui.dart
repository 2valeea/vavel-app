import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wc_typed_data_preview.dart';

/// Readable line length for WalletConnect bottom sheets on tablets / wide phones.
const double kWcSheetMaxContentWidth = 520;

void wcHapticReject() => HapticFeedback.lightImpact();

void wcHapticConfirm() => HapticFeedback.mediumImpact();

/// Centers sheet content and caps width so previews stay readable on large screens.
class WcSheetMaxWidth extends StatelessWidget {
  const WcSheetMaxWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kWcSheetMaxContentWidth),
        child: child,
      ),
    );
  }
}

Color wcPreviewKindAccent(TypedDataPreviewKind kind) {
  return switch (kind) {
    TypedDataPreviewKind.permit2 => const Color(0xFF26A69A),
    TypedDataPreviewKind.permitEip2612 => const Color(0xFF42A5F5),
    TypedDataPreviewKind.safeTx => const Color(0xFF7E57C2),
    TypedDataPreviewKind.safeMessage => const Color(0xFF9575CD),
    TypedDataPreviewKind.generic => const Color(0xFF78909C),
  };
}

String wcPreviewKindLabel(TypedDataPreviewKind kind) {
  return switch (kind) {
    TypedDataPreviewKind.permit2 => 'Permit2',
    TypedDataPreviewKind.permitEip2612 => 'EIP-2612',
    TypedDataPreviewKind.safeTx => 'Safe tx',
    TypedDataPreviewKind.safeMessage => 'Safe message',
    TypedDataPreviewKind.generic => 'EIP-712',
  };
}

/// Small label above the main preview card (typed data).
Widget wcTypedDataKindPill(TypedDataPreviewKind kind) {
  final accent = wcPreviewKindAccent(kind);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent.withValues(alpha: 0.45)),
    ),
    child: Text(
      wcPreviewKindLabel(kind),
      style: TextStyle(
        color: accent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// One human-preview bullet: emphasized label, calmer body (amounts, addresses).
Widget wcPreviewBulletLine(String line) {
  const bulletColor = Color(0xFF4DB6AC);
  final sep = line.indexOf(': ');
  if (sep <= 0) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.fiber_manual_record, size: 7, color: bulletColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              line,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.4, color: Color(0xFFECEFF1)),
            ),
          ),
        ],
      ),
    );
  }
  final label = line.substring(0, sep);
  final value = line.substring(sep + 2);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.fiber_manual_record, size: 7, color: bulletColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText.rich(
            TextSpan(
              style: const TextStyle(
                  fontSize: 13.5, height: 1.4, color: Color(0xFFECEFF1)),
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const TextSpan(
                    text: ':\n',
                    style: TextStyle(color: Color(0xFF78909C), fontSize: 11)),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

BoxDecoration wcPreviewCardDecoration({required Color borderAccent}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1E3550),
        const Color(0xFF172A40).withValues(alpha: 0.95),
      ],
    ),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: borderAccent.withValues(alpha: 0.4)),
    boxShadow: [
      BoxShadow(
        color: borderAccent.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

Widget wcSecurityCallout({
  required String text,
  required Color accent,
  IconData icon = Icons.shield_outlined,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accent.withValues(alpha: 0.38)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: accent.withValues(alpha: 0.95),
                fontSize: 12.5,
                height: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// Standard reject / confirm row for WalletConnect sheets.
class WcConfirmActionsRow extends StatelessWidget {
  const WcConfirmActionsRow({
    super.key,
    required this.rejectLabel,
    required this.confirmLabel,
    required this.onReject,
    required this.onApprove,
    this.confirmEnabled = true,
  });

  final String rejectLabel;
  final String confirmLabel;
  final Future<void> Function() onReject;
  final Future<void> Function() onApprove;
  final bool confirmEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;

    final rejectBtn = OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side:
            BorderSide(color: Colors.blueGrey.shade300.withValues(alpha: 0.5)),
      ),
      onPressed: () async {
        wcHapticReject();
        await onReject();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Text(rejectLabel),
    );

    final confirmBtn = FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: theme.colorScheme.primary,
      ),
      onPressed: !confirmEnabled
          ? null
          : () async {
              wcHapticConfirm();
              await onApprove();
              if (context.mounted) Navigator.of(context).pop();
            },
      child: Text(confirmLabel),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rejectBtn,
          const SizedBox(height: 10),
          confirmBtn,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: rejectBtn),
        const SizedBox(width: 12),
        Expanded(child: confirmBtn),
      ],
    );
  }
}
