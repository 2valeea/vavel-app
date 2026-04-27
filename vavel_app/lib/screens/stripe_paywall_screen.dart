import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../app_navigator.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';
import '../stripe/stripe_config.dart';

/// One-time access via **Stripe Checkout** (browser). Return: `/success` → deep link → [StripeReturnListener].
class StripePaywallScreen extends ConsumerStatefulWidget {
  const StripePaywallScreen({super.key});

  @override
  ConsumerState<StripePaywallScreen> createState() => _StripePaywallScreenState();
}

class _StripePaywallScreenState extends ConsumerState<StripePaywallScreen> {
  bool _busy = false;

  void _showSnack(String message, {Color? background}) {
    final ctx = appNavigatorKey.currentContext ?? context;
    if (!ctx.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: background ?? const Color(0xFF37474F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
  }

  String? _readServerError(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>?;
      final e = m?['error'];
      if (e is String && e.trim().isNotEmpty) return e.trim();
    } catch (_) {}
    return null;
  }

  Future<void> _pay() async {
    final s = ref.read(stringsProvider);
    final base = StripeConfig.backendBaseUrl.trim();
    if (base.isEmpty) {
      _showSnack(s.stripeMissingBackendUrl, background: const Color(0xFF5D4037));
      return;
    }

    setState(() => _busy = true);

    try {
      final uri = StripeConfig.createCheckoutSessionUri;
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': StripeConfig.unlockAmountMinor,
              'currency': StripeConfig.unlockCurrency,
              'productName': 'Wallet Vaval access',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final serverMsg = _readServerError(res.body);
        final msg = serverMsg ??
            (res.statusCode >= 500 ? s.stripeNetworkError : '${s.stripeNetworkError} (${res.statusCode})');
        _showSnack(msg, background: const Color(0xFFB71C1C));
        return;
      }

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final checkoutUrl = map['url'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        _showSnack(s.stripeNetworkError, background: const Color(0xFFB71C1C));
        return;
      }

      final checkoutUri = Uri.parse(checkoutUrl);
      final ok = await launchUrl(
        checkoutUri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        _showSnack(s.stripeBrowserOpenFailed, background: const Color(0xFFB71C1C));
        return;
      }

      if (mounted) {
        _showSnack(s.stripeOpeningBrowser, background: const Color(0xFF1B5E20));
      }
    } catch (_) {
      _showSnack(s.stripeNetworkError, background: const Color(0xFFB71C1C));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final priceLine = s.stripePriceLineTemplate
        .replaceAll('{amount}', StripeConfig.formattedUnlockTotal);
    final pkHint = StripeConfig.publishableKey.isEmpty ? s.stripePublishableKeyMissingHint : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.stripePaywallTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: s.paywallLock,
            icon: const Icon(Icons.lock_outline),
            onPressed: () => ref.read(appRouteProvider.notifier).lockWallet(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.stripePaywallBody,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                priceLine,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF90CAF9),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                '${s.stripeBackendLabel}\n${StripeConfig.backendBaseUrl}',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              if (pkHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  pkHint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.amber.withValues(alpha: 0.85),
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _pay,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.stripePayButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
