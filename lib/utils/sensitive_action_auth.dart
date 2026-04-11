import 'package:flutter/material.dart';

import '../screens/pin_setup_screen.dart' show PinPad;
import '../services/auth_service.dart';
import '../widgets/sensitive_screen_guard.dart';

/// Biometrics (if enabled) or PIN sheet. Returns `false` if cancelled / wrong PIN.
Future<bool> ensureSensitiveActionAuthenticated(
  BuildContext context, {
  required String biometricReason,
}) async {
  if (await AuthService.isBiometricAvailable() &&
      await AuthService.isBiometricEnabled()) {
    final bio = await AuthService.authenticateSensitiveWithBiometrics(
      localizedReason: biometricReason,
    );
    if (bio) return true;
  }
  if (!context.mounted) return false;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final pinOk = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: const Color(0xFF172434),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SensitiveScreenGuard(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SafeArea(
            child: SizedBox(
              height: 440,
              child: _PinConfirmContent(
                onSuccess: () {
                  Navigator.of(sheetContext).pop(true);
                },
                onFailed: () {
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect PIN'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
  return pinOk == true;
}

class _PinConfirmContent extends StatefulWidget {
  const _PinConfirmContent({
    required this.onSuccess,
    required this.onFailed,
  });

  final VoidCallback onSuccess;
  final VoidCallback onFailed;

  @override
  State<_PinConfirmContent> createState() => _PinConfirmContentState();
}

class _PinConfirmContentState extends State<_PinConfirmContent> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return PinPad(
      title: 'Enter PIN to confirm',
      subtitle: _error,
      onComplete: (pin) async {
        final ok = await AuthService.verifyPin(pin);
        if (!mounted) return;
        if (ok) {
          widget.onSuccess();
        } else {
          setState(() => _error = 'Incorrect PIN. Try again.');
          widget.onFailed();
        }
      },
    );
  }
}
