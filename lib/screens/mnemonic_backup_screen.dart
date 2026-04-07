import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';
import 'mnemonic_verify_screen.dart';

class MnemonicBackupScreen extends ConsumerWidget {
  const MnemonicBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonic = ref.watch(pendingMnemonicProvider) ?? '';
    final words = mnemonic.trim().split(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Back Up Seed Phrase'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B35)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Write these words down in order. Never share them with anyone.',
                        style:
                            TextStyle(color: Color(0xFFFF6B35), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: words.length,
                  itemBuilder: (_, i) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A3E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(
                          '${i + 1}.',
                          style: const TextStyle(
                              color: Color(0xFF2979FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          words[i],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy to Clipboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2979FF),
                  side: const BorderSide(color: Color(0xFF2979FF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MnemonicVerifyScreen(words: words),
                )),
                child: const Text("I've Written It Down — Verify"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
