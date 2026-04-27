import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../app_navigator.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';
import 'stripe_config.dart';
import 'stripe_unlock_store.dart';

/// Listens for `walletvaval://stripe-return?session_id=...` after the hosted `/success` page,
/// and `walletvaval://stripe-cancel` after `/canceled` or if the user aborts in-app flows.
class StripeReturnListener extends ConsumerStatefulWidget {
  const StripeReturnListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StripeReturnListener> createState() =>
      _StripeReturnListenerState();
}

class _StripeReturnListenerState extends ConsumerState<StripeReturnListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleInitialUri());
    });
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future.value());
    super.dispose();
  }

  Future<void> _handleInitialUri() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) await _handleUri(initial);
    } catch (_) {}
  }

  void _showSnack(String message, {Color? background}) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
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

  Future<void> _handleUri(Uri uri) async {
    if (uri.scheme != 'walletvaval') return;

    final s = ref.read(stringsProvider);

    if (uri.host == 'stripe-cancel') {
      _showSnack(s.stripeCheckoutCanceled, background: const Color(0xFF5D4037));
      return;
    }

    if (uri.host != 'stripe-return') return;

    final sessionId = uri.queryParameters['session_id'];
    if (sessionId == null || sessionId.isEmpty) return;

    final base = StripeConfig.backendBaseUrl.trim();
    if (base.isEmpty) return;

    try {
      final res = await http
          .get(StripeConfig.verifyCheckoutSessionUri(sessionId))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        _showSnack(s.stripeNetworkError, background: const Color(0xFFB71C1C));
        return;
      }

      final paid = _parsePaid(res.body);
      if (!paid) {
        _showSnack(s.stripePaymentNotCompleted, background: const Color(0xFFB71C1C));
        return;
      }

      await StripeUnlockStore.setUnlocked();
      if (!mounted) return;
      ref.read(appRouteProvider.notifier).completeStripeCheckoutAndShowThanks();
    } catch (_) {
      _showSnack(s.stripeNetworkError, background: const Color(0xFFB71C1C));
    }
  }

  bool _parsePaid(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>?;
      return m != null && m['paid'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
