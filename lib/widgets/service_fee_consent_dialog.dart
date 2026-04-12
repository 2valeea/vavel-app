import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../navigation/premium_page_route.dart';
import '../screens/legal_screens.dart';

/// Fee consent with Terms link and checkbox. Decline / dismiss without accept = no send.
class ServiceFeeConsentDialog extends StatefulWidget {
  const ServiceFeeConsentDialog({super.key, required this.strings});

  final S strings;

  static Future<bool?> show(BuildContext context, S strings) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ServiceFeeConsentDialog(strings: strings),
    );
  }

  @override
  State<ServiceFeeConsentDialog> createState() => _ServiceFeeConsentDialogState();
}

class _ServiceFeeConsentDialogState extends State<ServiceFeeConsentDialog> {
  bool _agreed = false;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () {
        pushPremium(context, const TermsOfServiceScreen());
      };
  }

  @override
  void dispose() {
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2A3E),
      title: Text(
        s.sendFeeConsentTitle,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.45,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(text: s.sendFeeConsentRichPart1),
                  TextSpan(
                    text: s.legalTermsTitle,
                    style: const TextStyle(
                      color: Color(0xFF90CAF9),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: _termsTap,
                  ),
                  TextSpan(text: s.sendFeeConsentRichPart2),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CheckboxTheme(
              data: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF00E676);
                  }
                  return Colors.white24;
                }),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: Text(
                  s.sendFeeConsentCheckbox,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(s.sendFeeConsentDecline),
        ),
        FilledButton(
          onPressed: _agreed ? () => Navigator.pop(context, true) : null,
          child: Text(s.sendFeeConsentAccept),
        ),
      ],
    );
  }
}
