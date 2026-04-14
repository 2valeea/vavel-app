import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/sensitive_screen_guard.dart';
import 'pin_setup_screen.dart' show PinPad;

/// Flow: verify main PIN → enter panic PIN twice (must differ from main).
class DuressPinSetupScreen extends StatefulWidget {
  const DuressPinSetupScreen({super.key});

  @override
  State<DuressPinSetupScreen> createState() => _DuressPinSetupScreenState();
}

enum _DuressStep { verifyMain, enterDuress, confirmDuress }

class _DuressPinSetupScreenState extends State<DuressPinSetupScreen> {
  _DuressStep _step = _DuressStep.verifyMain;
  String _duressFirst = '';
  bool _loading = false;
  String? _error;

  Future<void> _onPinEntered(String pin) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      switch (_step) {
        case _DuressStep.verifyMain:
          final ok = await AuthService.verifyPin(pin);
          if (!mounted) return;
          if (!ok) {
            setState(() => _error = 'Main PIN incorrect.');
            return;
          }
          setState(() => _step = _DuressStep.enterDuress);
        case _DuressStep.enterDuress:
          if (await AuthService.verifyPin(pin)) {
            if (!mounted) return;
            setState(() => _error = 'Panic PIN must differ from your main PIN.');
            return;
          }
          _duressFirst = pin;
          if (!mounted) return;
          setState(() => _step = _DuressStep.confirmDuress);
        case _DuressStep.confirmDuress:
          if (pin != _duressFirst) {
            if (!mounted) return;
            setState(() {
              _error = 'Panic PINs do not match. Start over.';
              _step = _DuressStep.enterDuress;
              _duressFirst = '';
            });
            return;
          }
          await AuthService.setDuressPin(pin);
          if (!mounted) return;
          Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _title {
    switch (_step) {
      case _DuressStep.verifyMain:
        return 'Enter your main PIN';
      case _DuressStep.enterDuress:
        return 'Create panic PIN (6 digits)';
      case _DuressStep.confirmDuress:
        return 'Confirm panic PIN';
    }
  }

  String get _subtitleText {
    switch (_step) {
      case _DuressStep.verifyMain:
        return 'Verify it’s you before setting a panic PIN.';
      case _DuressStep.enterDuress:
        return 'If forced to unlock, use this PIN. '
            'You’ll see a limited wallet; send & dApps stay blocked.';
      case _DuressStep.confirmDuress:
        return 'Enter the same panic PIN again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SensitiveScreenGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panic PIN'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      _subtitleText,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _loading,
                      child: PinPad(
                        title: _title,
                        subtitle: _error,
                        onComplete: _onPinEntered,
                      ),
                    ),
                  ),
                ],
              ),
              if (_loading)
                const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
