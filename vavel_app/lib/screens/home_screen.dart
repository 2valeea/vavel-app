import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/wallet_provider.dart';
import '../push/push_notification_service.dart';
import '../providers/balance_provider.dart';
import '../providers/price_provider.dart';
import '../providers/jupiter_tiktok_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/network_provider.dart';
import '../services/wallet_service.dart';
import '../solana/solana_rpc_client.dart' show SolanaRpcException;
import '../http/safe_http_client.dart' show NonJsonRpcResponse;
import 'send_screen.dart';
import 'receive_screen.dart';
import 'settings_screen.dart';
import 'swap_screen.dart';

import '../models/asset_id.dart';
import '../navigation/premium_page_route.dart';
import '../widgets/skeleton_shimmer.dart';

export '../models/asset.dart' show Asset, AssetType, kAssets;
export '../models/asset_id.dart' show AssetId, AssetInfo;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PushNotificationService.maybeInitializeAfterUnlock(ref);
    });
  }

  void _needMainPinSnack(S s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.duressActionBlocked)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(balanceProvider);
    final pricesAsync = ref.watch(priceProvider);
    final addressesAsync = ref.watch(walletAddressesProvider);
    final s = ref.watch(stringsProvider);
    final network = ref.watch(networkProvider);
    final isTestnet = network == AppNetwork.testnet;
    final duress = ref.watch(duressModeProvider);

    final prices = pricesAsync.valueOrNull ?? {};
    final jupTiktok = ref.watch(jupiterTiktokInfoProvider);

    String address(AssetId id) {
      final addrs = addressesAsync.valueOrNull;
      if (addrs == null) return '';
      switch (id) {
        case AssetId.sol:
        case AssetId.tiktok:
          return addrs.solana;
        case AssetId.ton:
          return addrs.ton;
        case AssetId.eth:
        case AssetId.vaval:
          return addrs.ethereum;
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
    final showBalanceSkeleton =
        balancesAsync.isLoading && !balancesAsync.hasValue;

    double portfolioTotal = 0;
    if (!duress) {
      for (final id in AssetId.values) {
        final price = id == AssetId.tiktok
            ? (jupTiktok.valueOrNull?.usdPrice ?? 0)
            : (id == AssetId.vaval ? 0.0 : (prices[id.ticker] ?? 0.0));
        final amount = balanceNum(id, balances) ?? 0;
        portfolioTotal += price * amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF2979FF),
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (isTestnet) ...[
              const SizedBox(width: 8),
              _TestnetBadge(),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_outlined),
            tooltip: s.swap,
            onPressed: duress
                ? () => _needMainPinSnack(s)
                : () => pushPremium(context, const SwapScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: s.settings,
            onPressed: () => pushPremium(context, const SettingsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: s.lockWallet,
            onPressed: () => ref.read(appRouteProvider.notifier).lockWallet(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceProvider);
          ref.invalidate(priceProvider);
          ref.invalidate(jupiterTiktokInfoProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Testnet warning bar at the very top
            if (isTestnet)
              SliverToBoxAdapter(
                child: _TestnetBanner(s.networkTestnetWarning),
              ),
            if (duress)
              SliverToBoxAdapter(
                child: _DuressBanner(message: s.duressModeBanner),
              ),
            SliverToBoxAdapter(
              child: showBalanceSkeleton
                  ? const HomePortfolioHeaderSkeleton()
                  : _PortfolioHeader(
                      total: portfolioTotal,
                      fmt: usdFmt,
                      loading: balancesAsync.isLoading && !duress,
                      s: s,
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
                if (showBalanceSkeleton)
                  ...List.generate(
                    5,
                    (_) => const HomeAssetTileSkeleton(),
                  )
                else
                  ...AssetId.values.map((id) {
                    final jup = jupTiktok.valueOrNull;
                    final price = id == AssetId.tiktok
                        ? jup?.usdPrice
                        : prices[id.ticker];
                    final amount = duress ? 0.0 : balanceNum(id, balances);
                    final usdValue = duress
                        ? 0.0
                        : (price != null && amount != null)
                            ? price * amount
                            : null;
                    return _AssetTile(
                      id: id,
                      displayName:
                          id == AssetId.tiktok ? (jup?.name) : null,
                      displayTicker:
                          id == AssetId.tiktok ? (jup?.symbol) : null,
                      imageUrl: id == AssetId.tiktok ? jup?.icon : null,
                      balance: balancesAsync.isLoading && !duress
                          ? null
                          : (duress ? '0' : balanceStr(id, balances)),
                      usdValue: usdValue,
                      usdFmt: usdFmt,
                      cryptoFmt: cryptoFmt,
                      loading: balancesAsync.isLoading && !duress,
                      priceLoading: (pricesAsync.isLoading &&
                              !duress &&
                              id != AssetId.tiktok) ||
                          (jupTiktok.isLoading && !duress && id == AssetId.tiktok),
                      s: s,
                      actionsEnabled: !duress,
                      onSend: () => pushPremium(
                        context,
                        SendScreen(assetId: id, address: address(id)),
                      ),
                      onReceive: () => pushPremium(
                        context,
                        ReceiveScreen(assetId: id, address: address(id)),
                      ),
                      onSwap: () =>
                          pushPremium(context, const SwapScreen()),
                      onBlocked: () => _needMainPinSnack(s),
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

class _DuressBanner extends StatelessWidget {
  final String message;

  const _DuressBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Colors.deepOrange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.deepOrange,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  final double total;
  final NumberFormat fmt;
  final bool loading;
  final S s;
  const _PortfolioHeader(
      {required this.total,
      required this.fmt,
      required this.loading,
      required this.s});

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
          Text(s.totalPortfolio,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          loading
              ? const SkeletonPulse(
                  width: 200,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                )
              : Text(fmt.format(total),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(s.usdValue,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final AssetId id;
  /// When set (e.g. Solana token from Jupiter), overrides [AssetInfo.label].
  final String? displayName;
  /// When set, overrides [AssetInfo.ticker] in the balance line.
  final String? displayTicker;
  final String? imageUrl;
  final String? balance;
  final double? usdValue;
  final NumberFormat usdFmt;
  final NumberFormat cryptoFmt;
  final bool loading;
  final bool priceLoading;
  final S s;
  final bool actionsEnabled;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onSwap;
  final VoidCallback onBlocked;

  const _AssetTile({
    required this.id,
    this.displayName,
    this.displayTicker,
    this.imageUrl,
    required this.balance,
    required this.usdValue,
    required this.usdFmt,
    required this.cryptoFmt,
    required this.loading,
    required this.priceLoading,
    required this.s,
    required this.actionsEnabled,
    required this.onSend,
    required this.onReceive,
    required this.onSwap,
    required this.onBlocked,
  });

  Widget _leadingAvatar() {
    if (id == AssetId.tiktok &&
        imageUrl != null &&
        imageUrl!.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(id.icon, color: id.color, size: 24),
          headers: const {'Accept': 'image/*'},
        ),
      );
    }
    return Icon(id.icon, color: id.color, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    final title = (displayName != null && displayName!.isNotEmpty)
        ? displayName!
        : id.label;
    final tkr =
        (displayTicker != null && displayTicker!.isNotEmpty) ? displayTicker! : id.ticker;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: id.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: _leadingAvatar(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    loading
                        ? const SkeletonPulse(
                            width: 80,
                            height: 12,
                            borderRadius:
                                BorderRadius.all(Radius.circular(6)),
                          )
                        : Text(
                            '${balance ?? '—'} $tkr',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Fixed max width so the title column keeps almost all row width
              // (avoids letter-by-letter wrap when USD text competes in a Flex).
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 104),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: (loading || priceLoading)
                      ? const SkeletonPulse(
                          width: 60,
                          height: 14,
                          borderRadius:
                              BorderRadius.all(Radius.circular(6)),
                        )
                      : Text(
                          usdValue != null
                              ? usdFmt.format(usdValue)
                              : (id == AssetId.tiktok ? '—' : s.priceUnavailable),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                _ActionChip(
                    label: s.send,
                    icon: Icons.arrow_upward,
                    color: id.color,
                    enabled: actionsEnabled,
                    onTap: onSend,
                    onBlocked: onBlocked),
                _ActionChip(
                    label: s.receive,
                    icon: Icons.arrow_downward,
                    color: id.color,
                    enabled: actionsEnabled,
                    onTap: onReceive,
                    onBlocked: onBlocked),
                _ActionChip(
                    label: s.swap,
                    icon: Icons.swap_horiz,
                    color: id.color,
                    enabled: actionsEnabled,
                    onTap: onSwap,
                    onBlocked: onBlocked),
              ],
            ),
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
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onBlocked;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        enabled ? color : color.withValues(alpha: 0.35);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : onBlocked,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: effectiveColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(
                      color: effectiveColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
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
            name: 'wallet_app',
          );
        }
        final hint = switch (chain) {
          'sol' || 'solana' => '--dart-define=SOLANA_RPC_PRIMARY=https://...',
          'ton' => '--dart-define=TONCENTER_API_KEY=YOUR_KEY',
          'eth' || 'vaval' => '--dart-define=ETH_RPC_URL=https://...',
          _ => 'an authenticated RPC endpoint',
        };
        return 'RPC requires authentication (HTTP ${err.statusCode}). '
            'Set $hint with a valid API key.';
      }
      if (err.isRateLimited) {
        if (kDebugMode) {
          log('[$chain] rate-limited (429)', name: 'wallet_app');
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
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            // Read strings from nearest ConsumerWidget ancestor via InheritedWidget is not
            // possible here (StatelessWidget); use a hard-coded fallback instead.
            // The banner text is a secondary detail so this is acceptable.
            return const Row(
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
            );
          }),
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

// ── Testnet badge (AppBar title) ──────────────────────────────────────────

class _TestnetBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: const Text(
        'TESTNET',
        style: TextStyle(
          color: Colors.orange,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Testnet warning banner (body) ─────────────────────────────────────────

class _TestnetBanner extends StatelessWidget {
  final String message;
  const _TestnetBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Colors.orange, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
