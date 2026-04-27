import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';

/// Shown after a successful Stripe Checkout return (deep link verified).
class PaymentThankYouScreen extends ConsumerWidget {
  const PaymentThankYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.stripeThankYouTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 72),
              const SizedBox(height: 24),
              Text(
                s.stripeThankYouBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => ref
                    .read(appRouteProvider.notifier)
                    .leavePaymentThanksToHome(),
                child: Text(s.stripeThankYouContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
