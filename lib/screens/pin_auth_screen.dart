import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/wallet_provider.dart';
import 'pin_setup_screen.dart' show PinPad;

class PinAuthScreen extends ConsumerStatefulWidget {
  const PinAuthScreen({super.key});

  @override
  ConsumerState<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends ConsumerState<PinAuthScreen> {
  bool _biometricAvailable = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await AuthService.isBiometricAvailable();
    final enabled = await AuthService.isBiometricEnabled();
    if (available && enabled) {
      setState(() => _biometricAvailable = true);
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_loading) return;
    try {
      setState(() => _loading = true);
      final ok = await AuthService.authenticateWithBiometrics();
      if (ok && mounted) {
        ref.read(appRouteProvider.notifier).goHome();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onPinEntered(String pin) async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final ok = await AuthService.verifyPin(pin);
      if (!mounted) return;
      if (ok) {
        ref.read(appRouteProvider.notifier).goHome();
      } else {
        setState(() => _error = 'Incorrect PIN. Try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/VAVEL.jpeg',
                        height: 36,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF2979FF),
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('VAVEL WALLET',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: _loading,
                    child: PinPad(
                      title: 'Enter your PIN',
                      subtitle: _error,
                      onComplete: _onPinEntered,
                    ),
                  ),
                ),
                if (_biometricAvailable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: TextButton.icon(
                      onPressed: _loading ? null : _tryBiometric,
                      icon: const Icon(Icons.fingerprint,
                          size: 28, color: Color(0xFF2979FF)),
                      label: const Text('Use Biometrics',
                          style: TextStyle(color: Color(0xFF2979FF))),
                    ),
                  ),
              ],
            ),
            if (_loading)
              const ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF2979FF)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
