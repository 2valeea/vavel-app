import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/premium_page_route.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';
import '../crypto/mnemonic.dart';
import 'mnemonic_backup_screen.dart';
import 'pin_setup_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _loading = false;
  bool _importing = false;
  final _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    setState(() => _loading = true);
    try {
      final mnemonic = await generateMnemonic(12);
      ref.read(pendingMnemonicProvider.notifier).state = mnemonic;
      if (!mounted) return;
      await pushPremium(context, const MnemonicBackupScreen());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importWallet() async {
    final words = _importController.text.trim();
    if (!validateMnemonic(words)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid mnemonic phrase')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(seedStoreProvider).saveMnemonic(words);
      if (!mounted) return;
      await pushPremium(
        context,
        PinSetupScreen(onComplete: () {
          ref.read(appRouteProvider.notifier).goHome();
        }),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/VAVEL.jpeg',
                  height: 80,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Color(0xFF2979FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                s.appTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your gateway to multi-chain finance',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _loading ? null : _createWallet,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create New Wallet'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() => _importing = !_importing),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2979FF),
                  side: const BorderSide(color: Color(0xFF2979FF)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Import Existing Wallet'),
              ),
              if (_importing) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _importController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter 12 or 24 seed words separated by spaces',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1A2A3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _importWallet,
                  child: const Text('Import Wallet'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
