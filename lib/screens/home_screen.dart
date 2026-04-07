import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/asset.dart';
import '../providers/wallet_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/price_provider.dart';
import '../services/wallet_service.dart';
import '../solana/solana_rpc_client.dart' show SolanaRpcException;
import '../http/safe_http_client.dart' show NonJsonRpcResponse;
import 'send_screen.dart';
import 'receive_screen.dart';

export '../models/asset.dart' show Asset, AssetType, kAssets;

enum AssetId { vavel, btc, eth, sol, ton }

extension AssetInfo on AssetId {
  Asset get asset => kAssets.firstWhere((a) => a.id == name);

  String get label => asset.name;
  String get ticker => asset.symbol;
  String? get geckoId => asset.geckoId;

  Color get color {
    switch (this) {
      case AssetId.vavel:
        return const Color(0xFF2979FF);
      case AssetId.btc:
        return const Color(0xFFF7931A);
      case AssetId.eth:
        return const Color(0xFF627EEA);
      case AssetId.sol:
        return const Color(0xFF9945FF);
      case AssetId.ton:
        return const Color(0xFF0098EA);
    }
  }

  IconData get icon {
    switch (this) {
      case AssetId.vavel:
        return Icons.token;
      case AssetId.btc:
        return Icons.currency_bitcoin;
      case AssetId.eth:
        return Icons.diamond_outlined;
      case AssetId.sol:
        return Icons.blur_circular;
      case AssetId.ton:
        return Icons.hub_outlined;
    }
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(balanceProvider);
    final pricesAsync = ref.watch(priceProvider);
    final addressesAsync = ref.watch(walletAddressesProvider);

    final prices = pricesAsync.valueOrNull ?? {};

    String address(AssetId id) {
      final addrs = addressesAsync.valueOrNull;
      if (addrs == null) return '';
      switch (id) {
        case AssetId.vavel:
        case AssetId.eth:
          return addrs.ethereum;
        case AssetId.btc:
          return addrs.bitcoin;
        case AssetId.sol:
          return addrs.solana;
        case AssetId.ton:
          return addrs.ton;
      }
    }

    String balanceStr(AssetId id, WalletBalances? b) {
      if (b == null) return '—';
      final bal = b[id.name];
      if (bal == null) return '—';
      return NumberFormat('#,##0.########').format(bal.toDecimal());
    }

    double? balanceNum(AssetId id, WalletBalances? b) {
      if (b == null) return null;
      return b[id.name]?.toDecimal();
    }

    final balances = balancesAsync.valueOrNull;
    final usdFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final cryptoFmt = NumberFormat('#,##0.########');

    double portfolioTotal = 0;
    for (final id in AssetId.values) {
      final price = id.geckoId != null ? (prices[id.geckoId] ?? 0) : 0;
      final amount = balanceNum(id, balances) ?? 0;
      portfolioTotal += price * amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/VAVEL.jpeg',
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF2979FF),
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            const Text('VAVEL WALLET',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Lock wallet',
            onPressed: () => ref.read(appRouteProvider.notifier).lockWallet(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceProvider);
          ref.invalidate(priceProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _PortfolioHeader(
                total: portfolioTotal,
                fmt: usdFmt,
                loading: balancesAsync.isLoading,
              ),
            ),
            if (balancesAsync.hasError)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    _formatBalanceError(balancesAsync.error),
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ),
            if (balancesAsync.valueOrNull?.hasErrors == true)
              SliverToBoxAdapter(
                child: _ChainErrorBanner(
                  errors: balancesAsync.value!.errors,
                ),
              ),
            SliverList(
              delegate: SliverChildListDelegate([
                ...AssetId.values.map((id) {
                  final price = id.geckoId != null ? prices[id.geckoId] : null;
                  final amount = balanceNum(id, balances);
                  final usdValue =
                      (price != null && amount != null) ? price * amount : null;
                  return _AssetTile(
                    id: id,
                    balance: balancesAsync.isLoading
                        ? null
                        : balanceStr(id, balances),
                    usdValue: usdValue,
                    usdFmt: usdFmt,
                    cryptoFmt: cryptoFmt,
                    loading: balancesAsync.isLoading,
                    onSend: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          SendScreen(assetId: id, address: address(id)),
                    )),
                    onReceive: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ReceiveScreen(assetId: id, address: address(id)),
                    )),
                  );
                }),
                const SizedBox(height: 24),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatBalanceError(Object? error) {
  if (error is NonJsonRpcResponse) return 'Balance error: ${error.userMessage}';
  return 'Balance error: $error';
}

class _PortfolioHeader extends StatelessWidget {
  final double total;
  final NumberFormat fmt;
  final bool loading;
  const _PortfolioHeader(
      {required this.total, required this.fmt, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A3E), Color(0xFF0D1B2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('Total Portfolio',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          loading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Text(fmt.format(total),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('USD Value',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final AssetId id;
  final String? balance;
  final double? usdValue;
  final NumberFormat usdFmt;
  final NumberFormat cryptoFmt;
  final bool loading;
  final VoidCallback onSend;
  final VoidCallback onReceive;

  const _AssetTile({
    required this.id,
    required this.balance,
    required this.usdValue,
    required this.usdFmt,
    required this.cryptoFmt,
    required this.loading,
    required this.onSend,
    required this.onReceive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: id.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: id == AssetId.vavel
                ? ClipOval(
                    child: Image.asset('assets/images/VAVEL.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(id.icon, color: id.color, size: 24)))
                : Icon(id.icon, color: id.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                loading
                    ? Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6)))
                    : Text('${balance ?? '—'} ${id.ticker}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              loading
                  ? Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6)))
                  : Text(
                      usdValue != null
                          ? usdFmt.format(usdValue)
                          : (id == AssetId.vavel ? '—' : r'$0.00'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Row(children: [
                _ActionChip(
                    label: 'Send',
                    icon: Icons.arrow_upward,
                    color: id.color,
                    onTap: onSend),
                const SizedBox(width: 6),
                _ActionChip(
                    label: 'Receive',
                    icon: Icons.arrow_downward,
                    color: id.color,
                    onTap: onReceive),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Displays a collapsible banner listing which chains failed to fetch
/// balances and why.
///
/// [SolanaRpcException] errors are given a specific, actionable message so
/// users know whether the problem is a bad API key (403) or a network issue.
class _ChainErrorBanner extends StatelessWidget {
  final Map<String, Object> errors;

  const _ChainErrorBanner({required this.errors});

  String _message(String chain, Object err) {
    if (err is SolanaRpcException) {
      if (err.isForbidden) {
        return 'RPC 403 — API key rejected. Set --dart-define=SOLANA_RPC_PRIMARY=https://... with a valid key.';
      }
      if (err.isTimeout) {
        return 'RPC timeout — check your internet connection.';
      }
      return 'RPC error (HTTP ${err.statusCode})';
    }
    if (err is NonJsonRpcResponse) {
      if (err.isAuthError) {
        // Covers HTTP 401/403 AND plain-text "Must be authenticated" (HTTP 200)
        // from endpoints like llamarpc that set Content-Type: application/json
        // but return a non-JSON auth error body.
        if (kDebugMode) {
          log(
            '[$chain] auth error — HTTP ${err.statusCode}: '
            '"${err.bodyStart.length > 60 ? err.bodyStart.substring(0, 60) : err.bodyStart}"',
            name: 'vavel_wallet',
          );
        }
        final hint = switch (chain) {
          'eth' || 'ethereum' => '--dart-define=ETH_RPC_URL=https://...',
          'sol' || 'solana' => '--dart-define=SOLANA_RPC_PRIMARY=https://...',
          'ton' => '--dart-define=TONCENTER_API_KEY=YOUR_KEY',
          _ => 'an authenticated RPC endpoint',
        };
        return 'RPC requires authentication (HTTP ${err.statusCode}). '
            'Set $hint with a valid API key.';
      }
      if (err.isRateLimited) {
        if (kDebugMode) {
          log('[$chain] rate-limited (429)', name: 'vavel_wallet');
        }
        return 'RPC rate-limited (429). Add an API key or reduce request frequency.';
      }
      return 'RPC error (HTTP ${err.statusCode}) — unexpected non-JSON response.';
    }
    return err.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 14, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                'Some balances unavailable',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...errors.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${e.key.toUpperCase()}: ${_message(e.key, e.value)}',
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
