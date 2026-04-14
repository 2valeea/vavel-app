import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/premium_page_route.dart';
import '../widgets/sensitive_screen_guard.dart';
import '../providers/wallet_provider.dart';
import 'pin_setup_screen.dart';

class MnemonicVerifyScreen extends ConsumerStatefulWidget {
  final List<String> words;
  const MnemonicVerifyScreen({super.key, required this.words});

  @override
  ConsumerState<MnemonicVerifyScreen> createState() =>
      _MnemonicVerifyScreenState();
}

class _MnemonicVerifyScreenState extends ConsumerState<MnemonicVerifyScreen> {
  late final List<_VerifyItem> _checks;
  late final List<List<String>> _options;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // Pick 3 random positions to verify
    final indices = List.generate(widget.words.length, (i) => i)..shuffle(rng);
    final picked = indices.take(3).toList()..sort();

    _checks = picked
        .map((i) => _VerifyItem(index: i, correct: widget.words[i]))
        .toList();

    // Build option lists: correct + 3 random distractors
    _options = _checks.map((item) {
      final distractors = widget.words.where((w) => w != item.correct).toList()
        ..shuffle(rng);
      final opts = [item.correct, ...distractors.take(3)]..shuffle(rng);
      return opts;
    }).toList();
  }

  bool get _allCorrect => _checks.every((c) => c.selected == c.correct);
  bool get _allAnswered => _checks.every((c) => c.selected != null);

  Future<void> _proceed() async {
    final mnemonic = widget.words.join(' ');
    await ref.read(seedStoreProvider).saveMnemonic(mnemonic);
    if (!mounted) return;
    // Capture the notifier before navigation so the closure doesn't reference
    // 'ref' after this widget is disposed by pushReplacement.
    final routeNotifier = ref.read(appRouteProvider.notifier);
    await pushReplacementPremium(
      context,
      PinSetupScreen(onComplete: () => routeNotifier.goHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SensitiveScreenGuard(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Verify Seed Phrase'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select the correct words to confirm you saved your seed phrase.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...List.generate(_checks.length, (i) {
                final item = _checks[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Word #${item.index + 1}',
                      style: const TextStyle(
                          color: Color(0xFF2979FF),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _options[i].map((opt) {
                        final selected = item.selected == opt;
                        final wrong = selected && opt != item.correct;
                        return GestureDetector(
                          onTap: () => setState(() => item.selected = opt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: wrong
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : selected
                                      ? const Color(0xFF2979FF)
                                          .withValues(alpha: 0.3)
                                      : const Color(0xFF1A2A3E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: wrong
                                    ? Colors.red
                                    : selected
                                        ? const Color(0xFF2979FF)
                                        : Colors.transparent,
                              ),
                            ),
                            child: Text(opt,
                                style: const TextStyle(color: Colors.white)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),
              const Spacer(),
              if (_allAnswered && !_allCorrect)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Some answers are wrong. Check again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ElevatedButton(
                onPressed: (_allAnswered && _allCorrect) ? _proceed : null,
                child: const Text('Confirm & Set PIN'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _VerifyItem {
  final int index;
  final String correct;
  String? selected;
  _VerifyItem({required this.index, required this.correct});
}
