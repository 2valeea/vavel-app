import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/portfolio_provider.dart';

/// Lightweight dashboard that lists BTC + ETH/ERC-20 balances
/// fetched via [PortfolioService].
///
/// Addresses are derived automatically from the stored mnemonic — no
/// hardcoded values. For the full wallet UI see [HomeScreen].
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(portfolioBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Dashboard')),
      body: balancesAsync.when(
        data: (balances) => ListView.separated(
          itemCount: balances.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final b = balances[i];
            final amount = b.toDecimal().toStringAsFixed(6);
            return ListTile(
              title: Text(b.symbol),
              subtitle: Text('Balance: $amount'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
