import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
import '../providers/network_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final network = ref.watch(networkProvider);
    final isTestnet = network == AppNetwork.testnet;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
        actions: [
          // Live network badge in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _NetworkBadge(isTestnet: isTestnet),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Testnet warning banner ─────────────────────────────────────
          if (isTestnet) ...[
            _WarningBanner(s.networkTestnetWarning),
            const SizedBox(height: 16),
          ],

          // ── Language ──────────────────────────────────────────────────
          _SectionHeader(s.language),
          const SizedBox(height: 8),
          _LanguageTile(
            label: s.langEnglish,
            languageCode: 'en',
            selected: locale.languageCode == 'en',
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('en')),
          ),
          const SizedBox(height: 6),
          _LanguageTile(
            label: s.langRussian,
            languageCode: 'ru',
            selected: locale.languageCode == 'ru',
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('ru')),
          ),

          // ── Network ───────────────────────────────────────────────────
          const SizedBox(height: 24),
          _SectionHeader(s.network),
          const SizedBox(height: 8),
          _NetworkTile(
            label: s.networkMainnet,
            description: s.networkMainnetDesc,
            network: AppNetwork.mainnet,
            selected: network == AppNetwork.mainnet,
            onTap: () => ref
                .read(networkProvider.notifier)
                .setNetwork(AppNetwork.mainnet),
          ),
          const SizedBox(height: 6),
          _NetworkTile(
            label: s.networkTestnet,
            description: s.networkTestnetDesc,
            network: AppNetwork.testnet,
            selected: network == AppNetwork.testnet,
            onTap: () => _confirmTestnet(
              context,
              ref,
              s.networkTestnetWarning,
            ),
          ),

          // ── RPC tips ──────────────────────────────────────────────────
          const SizedBox(height: 24),
          const _SectionHeader('API Keys (RPC)'),
          const SizedBox(height: 8),
          _RpcKeyTip(
            chain: 'Ethereum',
            hint: s.rpcKeyHintEth,
            color: const Color(0xFF627EEA),
          ),
          const SizedBox(height: 6),
          _RpcKeyTip(
            chain: 'Solana',
            hint: s.rpcKeyHintSol,
            color: const Color(0xFF9945FF),
          ),
          const SizedBox(height: 6),
          _RpcKeyTip(
            chain: 'TON',
            hint: s.rpcKeyHintTon,
            color: const Color(0xFF0098EA),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmTestnet(
    BuildContext context,
    WidgetRef ref,
    String warning,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3E),
        title: const Text('Switch to Testnet?'),
        content: Text(
          warning,
          style: const TextStyle(color: Colors.orange),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Switch', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(networkProvider.notifier).setNetwork(AppNetwork.testnet);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String languageCode;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : const Color(0xFF1A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              languageCode == 'ru' ? '🇷🇺' : '🇬🇧',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Network tile ──────────────────────────────────────────────────────────

class _NetworkTile extends StatelessWidget {
  final String label;
  final String description;
  final AppNetwork network;
  final bool selected;
  final VoidCallback onTap;

  const _NetworkTile({
    required this.label,
    required this.description,
    required this.network,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTestnet = network == AppNetwork.testnet;
    final indicatorColor = isTestnet ? Colors.orange : Colors.greenAccent;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isTestnet
                  ? Colors.orange.withValues(alpha: 0.08)
                  : accent.withValues(alpha: 0.08))
              : const Color(0xFF1A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? (isTestnet ? Colors.orange : accent)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Live indicator dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: selected ? indicatorColor : Colors.grey.shade700,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: indicatorColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                        )
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isTestnet ? Colors.orange.shade200 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: indicatorColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Network badge (AppBar) ────────────────────────────────────────────────

class _NetworkBadge extends StatelessWidget {
  final bool isTestnet;
  const _NetworkBadge({required this.isTestnet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTestnet
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.greenAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTestnet ? Colors.orange : Colors.greenAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isTestnet ? Colors.orange : Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isTestnet ? 'TESTNET' : 'MAINNET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isTestnet ? Colors.orange : Colors.greenAccent,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Testnet warning banner ────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── RPC key tip ───────────────────────────────────────────────────────────

class _RpcKeyTip extends StatelessWidget {
  final String chain;
  final String hint;
  final Color color;

  const _RpcKeyTip({
    required this.chain,
    required this.hint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: color, size: 14),
              const SizedBox(width: 6),
              Text(chain,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            hint,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
