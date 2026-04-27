import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../navigation/premium_page_route.dart';
import '../providers/locale_provider.dart';
import '../providers/network_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/auth_service.dart';
import 'address_book_screen.dart';
import 'duress_pin_setup_screen.dart';
import 'history_screen.dart';
import 'legal_screens.dart';
import 'pin_setup_screen.dart';
import 'support_screen.dart';
// ── Notifications preferences provider ───────────────────────────────────

const _kNotifyTx = 'notify_tx';
const _kNotifyPrice = 'notify_price';
const _kStorage = FlutterSecureStorage();

final notifyTxProvider = StateNotifierProvider<_BoolNotifier, bool>(
    (ref) => _BoolNotifier(_kNotifyTx, defaultValue: true));
final notifyPriceProvider = StateNotifierProvider<_BoolNotifier, bool>(
    (ref) => _BoolNotifier(_kNotifyPrice, defaultValue: false));

class _BoolNotifier extends StateNotifier<bool> {
  final String _key;
  _BoolNotifier(this._key, {required bool defaultValue}) : super(defaultValue) {
    _load();
  }
  Future<void> _load() async {
    final val = await _kStorage.read(key: _key);
    if (val != null && mounted) state = val == 'true';
  }

  Future<void> toggle() async {
    state = !state;
    await _kStorage.write(key: _key, value: state ? 'true' : 'false');
  }
}

// ── Biometrics availability provider ────────────────────────────────────

final biometricAvailableProvider =
    FutureProvider<bool>((_) => AuthService.isBiometricAvailable());
final biometricEnabledProvider =
    StateNotifierProvider<_BiometricNotifier, bool>(
        (ref) => _BiometricNotifier());

class _BiometricNotifier extends StateNotifier<bool> {
  _BiometricNotifier() : super(false) {
    _load();
  }
  Future<void> _load() async {
    final v = await AuthService.isBiometricEnabled();
    if (mounted) state = v;
  }

  Future<void> toggle() async {
    final next = !state;
    await AuthService.setBiometricEnabled(next);
    state = next;
  }
}

Future<void> _openLegalFeesHub(BuildContext context, WidgetRef ref) async {
  final s = ref.read(stringsProvider);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF172434),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              s.legalFeesHubTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              s.legalFeesHubDesc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined, color: Color(0xFF90CAF9)),
            title: Text(
              s.legalFeesMenuOpenTerms,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(ctx);
              pushPremium(context, const TermsOfServiceScreen());
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.privacy_tip_outlined, color: Color(0xFFCE93D8)),
            title: Text(
              s.legalFeesMenuOpenPrivacy,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(ctx);
              pushPremium(context, const PrivacyPolicyScreen());
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Settings screen ───────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final network = ref.watch(networkProvider);
    final isTestnet = network == AppNetwork.testnet;
    final notifyTx = ref.watch(notifyTxProvider);
    final notifyPrice = ref.watch(notifyPriceProvider);
    final biometricAvailable =
        ref.watch(biometricAvailableProvider).valueOrNull ?? false;
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final duressConfigured =
        ref.watch(duressPinConfiguredProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _NetworkBadge(isTestnet: isTestnet),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Testnet warning banner ────────────────────────────────────
          if (isTestnet) ...[
            _WarningBanner(s.networkTestnetWarning),
            const SizedBox(height: 16),
          ],

          // ── Language ─────────────────────────────────────────────────
          _SectionHeader(s.language),
          const SizedBox(height: 8),
          ..._kLanguages.map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _LanguageTile(
                  label: lang.$1,
                  flag: lang.$2,
                  languageCode: lang.$3,
                  selected: locale.languageCode == lang.$3,
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(lang.$3)),
                ),
              )),

          // ── Security ─────────────────────────────────────────────────
          const SizedBox(height: 24),
          _SectionHeader(s.security),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.pin_outlined,
            iconColor: const Color(0xFF2979FF),
            label: s.changePin,
            description: s.changePinDesc,
            onTap: () {
              if (ref.read(duressModeProvider)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.duressSettingsBlocked)),
                );
                return;
              }
              pushPremium(
                context,
                PinSetupScreen(onComplete: () {}),
              );
            },
          ),
          const SizedBox(height: 6),
          _NavTile(
            icon: Icons.emergency_outlined,
            iconColor: Colors.deepOrange,
            label: s.panicPin,
            description: s.panicPinDesc,
            onTap: () async {
              if (ref.read(duressModeProvider)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.duressSettingsBlocked)),
                );
                return;
              }
              final ok = await pushPremium<bool>(
                context,
                const DuressPinSetupScreen(),
              );
              if (!context.mounted) return;
              if (ok == true) {
                ref.invalidate(duressPinConfiguredProvider);
              }
            },
          ),
          if (duressConfigured) ...[
            const SizedBox(height: 6),
            _NavTile(
              icon: Icons.delete_outline,
              iconColor: Colors.redAccent,
              label: s.panicPinRemove,
              description: s.panicPinRemoveConfirm,
              onTap: () async {
                if (ref.read(duressModeProvider)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.duressSettingsBlocked)),
                  );
                  return;
                }
                final go = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(s.panicPinRemove),
                    content: Text(s.panicPinRemoveConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (go == true) {
                  await AuthService.clearDuressPin();
                  if (!context.mounted) return;
                  ref.invalidate(duressPinConfiguredProvider);
                }
              },
            ),
          ],
          if (biometricAvailable) ...[
            const SizedBox(height: 6),
            _ToggleTile(
              icon: Icons.fingerprint,
              iconColor: Colors.greenAccent,
              label: s.biometrics,
              description: s.biometricsDesc,
              value: biometricEnabled,
              onToggle: () =>
                  ref.read(biometricEnabledProvider.notifier).toggle(),
            ),
          ],

          // ── Notifications ─────────────────────────────────────────────
          const SizedBox(height: 24),
          _SectionHeader(s.notifications),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFFFFAB40),
            label: s.notifyTransactions,
            description: s.notifyTransactionsDesc,
            value: notifyTx,
            onToggle: () => ref.read(notifyTxProvider.notifier).toggle(),
          ),
          const SizedBox(height: 6),
          _ToggleTile(
            icon: Icons.show_chart,
            iconColor: const Color(0xFF00E5FF),
            label: s.notifyPriceAlerts,
            description: s.notifyPriceAlertsDesc,
            value: notifyPrice,
            onToggle: () => ref.read(notifyPriceProvider.notifier).toggle(),
          ),

          // ── History ───────────────────────────────────────────────────
          const SizedBox(height: 24),
          _SectionHeader(s.history),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF9945FF),
            label: s.historyViewAll,
            description: s.history,
            onTap: () => pushPremium(context, const HistoryScreen()),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.contact_mail_outlined,
            iconColor: const Color(0xFF26A69A),
            label: 'Address book',
            description: 'Saved contacts for sending',
            onTap: () => pushPremium(context, const AddressBookScreen()),
          ),

          // ── Support ───────────────────────────────────────────────────
          const SizedBox(height: 24),
          _SectionHeader(s.support),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.support_agent,
            iconColor: const Color(0xFF2979FF),
            label: s.supportTitle,
            description: s.supportDesc,
            onTap: () => pushPremium(context, const SupportScreen()),
          ),

          // ── Legal ─────────────────────────────────────────────────────
          const SizedBox(height: 24),
          _SectionHeader(s.legalSection),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.article_outlined,
            iconColor: const Color(0xFF90CAF9),
            label: s.legalTermsTitle,
            description: s.legalTermsDesc,
            onTap: () => pushPremium(context, const TermsOfServiceScreen()),
          ),
          const SizedBox(height: 6),
          _NavTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFFCE93D8),
            label: s.legalPrivacyTitle,
            description: s.legalPrivacyDesc,
            onTap: () => pushPremium(context, const PrivacyPolicyScreen()),
          ),
          const SizedBox(height: 6),
          _NavTile(
            icon: Icons.gavel_outlined,
            iconColor: const Color(0xFFFFB74D),
            label: s.legalFeesHubTitle,
            description: s.legalFeesHubDesc,
            onTap: () => _openLegalFeesHub(context, ref),
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

}

// ── Language list constant ────────────────────────────────────────────────
// (label, flag emoji, languageCode)
const _kLanguages = [
  ('English', '🇬🇧', 'en'),
  ('Русский', '🇷🇺', 'ru'),
  ('Deutsch', '🇩🇪', 'de'),
  ('Dansk', '🇩🇰', 'da'),
  ('Eesti', '🇪🇪', 'et'),
  ('Português', '🇵🇹', 'pt'),
  ('Українська', '🇺🇦', 'uk'),
];

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
  final String flag;
  final String languageCode;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.flag,
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
                const Spacer(),
                if (selected) Icon(Icons.check_circle, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav tile (tap to navigate) ────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2A3E),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeThumbColor: const Color(0xFF2979FF),
          ),
        ],
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
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
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isTestnet
                              ? Colors.orange.shade200
                              : Colors.grey,
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
