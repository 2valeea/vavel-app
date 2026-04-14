import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/locale_provider.dart';
import '../providers/tx_history_provider.dart';
import '../providers/wc_activity_provider.dart';
import '../walletconnect/wc_activity_entry.dart';
import '../widgets/skeleton_shimmer.dart';

enum _ActivityFilter { all, onChain, dApp }

sealed class _FeedItem {
  DateTime get sortTime;
}

final class _FeedOnChain extends _FeedItem {
  _FeedOnChain(this.tx);
  final TxRecord tx;
  @override
  DateTime get sortTime => tx.timestamp;
}

final class _FeedWc extends _FeedItem {
  _FeedWc(this.entry);
  final WcActivityEntry entry;
  @override
  DateTime get sortTime => entry.at;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final txs = ref.watch(txHistoryProvider);
    final wcAsync = ref.watch(wcActivityLogProvider);
    final dateFmt = DateFormat('dd MMM yyyy · HH:mm');

    final wcItems = wcAsync.asData?.value ?? const <WcActivityEntry>[];
    final merged = <_FeedItem>[
      ...txs.map(_FeedOnChain.new),
      ...wcItems.map(_FeedWc.new),
    ]..sort((a, b) => b.sortTime.compareTo(a.sortTime));

    final visible = merged.where((item) {
      return switch (_filter) {
        _ActivityFilter.all => true,
        _ActivityFilter.onChain => item is _FeedOnChain,
        _ActivityFilter.dApp => item is _FeedWc,
      };
    }).toList();

    final wcLoading = wcAsync.isLoading;
    final wcErr = wcAsync.hasError;
    final showWcLoadingBar = wcLoading &&
        _filter != _ActivityFilter.onChain &&
        (txs.isNotEmpty || wcItems.isNotEmpty);

    Widget body;
    if (wcLoading && merged.isEmpty) {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => const SkeletonListTile(),
      );
    } else if (visible.isEmpty) {
      if (merged.isEmpty && wcErr) {
        body = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _WcErrorBanner(message: wcAsync.error.toString()),
          ),
        );
      } else {
        body = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  merged.isEmpty
                      ? Icons.timeline_outlined
                      : Icons.filter_alt_outlined,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 16),
                Text(
                  merged.isEmpty ? s.historyEmptyUnified : s.historyEmptyFilter,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      final tiles = <Widget>[];
      if (wcErr) {
        tiles.add(_WcErrorBanner(message: wcAsync.error.toString()));
        tiles.add(const SizedBox(height: 10));
      }
      if (showWcLoadingBar) {
        tiles.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 6),
                Text(
                  s.historyLoadingWcLine,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        );
        tiles.add(const SizedBox(height: 6));
      }
      for (final item in visible) {
        tiles.add(
          switch (item) {
            _FeedOnChain(:final tx) => _TxCard(
                tx: tx,
                dateFmt: dateFmt,
                badgeLabel: s.historyBadgeOnChain,
              ),
            _FeedWc(:final entry) => _WcActivityCard(
                entry: entry,
                dateFmt: dateFmt,
                badgeLabel: s.historyBadgeDapp,
              ),
          },
        );
        tiles.add(const SizedBox(height: 8));
      }
      if (tiles.isNotEmpty && tiles.last is SizedBox) {
        tiles.removeLast();
      }
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: tiles,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.history),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: s.historyChipAll,
                    selected: _filter == _ActivityFilter.all,
                    onTap: () => setState(() => _filter = _ActivityFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: s.historyTabOnChain,
                    selected: _filter == _ActivityFilter.onChain,
                    onTap: () => setState(() => _filter = _ActivityFilter.onChain),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: s.historyBadgeDapp,
                    selected: _filter == _ActivityFilter.dApp,
                    onTap: () => setState(() => _filter = _ActivityFilter.dApp),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (txs.isNotEmpty || wcItems.isNotEmpty)
            PopupMenuButton<_ClearAction>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Options',
              onSelected: (action) => _onClearMenu(context, ref, s, action),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ClearAction.onChain,
                  child: Text(s.historyMenuClearOnChain),
                ),
                PopupMenuItem(
                  value: _ClearAction.wc,
                  child: Text(s.historyMenuClearWc),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _ClearAction.all,
                  child: Text(
                    s.historyMenuClearAll,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: body,
    );
  }

  Future<void> _onClearMenu(
    BuildContext context,
    WidgetRef ref,
    S s,
    _ClearAction action,
  ) async {
    switch (action) {
      case _ClearAction.onChain:
        await _confirmClearOnChain(context, ref);
      case _ClearAction.wc:
        await _confirmClearWalletConnect(context, ref, s);
      case _ClearAction.all:
        await _confirmClearAll(context, ref, s);
    }
  }

  Future<void> _confirmClearOnChain(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3E),
        title: const Text('Clear history?'),
        content: const Text(
          'This removes all locally stored transaction records.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(txHistoryProvider.notifier).clear();
    }
  }

  Future<void> _confirmClearWalletConnect(
    BuildContext context,
    WidgetRef ref,
    S s,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3E),
        title: Text(s.historyClearWcTitle),
        content: Text(
          s.historyClearWcBody,
          style: const TextStyle(color: Colors.grey, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.historyClearWcAction,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(wcActivityLogProvider.notifier).clear();
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    WidgetRef ref,
    S s,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3E),
        title: Text(s.historyClearAllTitle),
        content: Text(
          s.historyClearAllBody,
          style: const TextStyle(color: Colors.grey, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(txHistoryProvider.notifier).clear();
      await ref.read(wcActivityLogProvider.notifier).clear();
    }
  }
}

enum _ClearAction { onChain, wc, all }

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2979FF).withValues(alpha: 0.25)
                : const Color(0xFF1A2A3E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2979FF)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _WcErrorBanner extends ConsumerWidget {
  const _WcErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              '${s.historyWcLoadErrorLead}\n\n$message',
              style: const TextStyle(fontSize: 12.5, height: 1.35, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _WcActivityCard extends StatelessWidget {
  const _WcActivityCard({
    required this.entry,
    required this.dateFmt,
    required this.badgeLabel,
  });

  final WcActivityEntry entry;
  final DateFormat dateFmt;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final icon = switch (entry.outcome) {
      WcActivityOutcome.success => Icons.check_circle_outline,
      WcActivityOutcome.rejected => Icons.cancel_outlined,
      WcActivityOutcome.error => Icons.error_outline,
    };
    final color = switch (entry.outcome) {
      WcActivityOutcome.success => Colors.greenAccent,
      WcActivityOutcome.rejected => Colors.orangeAccent,
      WcActivityOutcome.error => Colors.redAccent,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(label: badgeLabel, color: const Color(0xFF26A69A)),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.dappName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (entry.detail != null && entry.detail!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SelectableText(
                    entry.detail!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(entry.at.toLocal()),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  const _TxCard({
    required this.tx,
    required this.dateFmt,
    required this.badgeLabel,
  });

  final TxRecord tx;
  final DateFormat dateFmt;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final amtFmt = NumberFormat('#,##0.########');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_upward,
                size: 18, color: Color(0xFF2979FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(label: badgeLabel, color: const Color(0xFF2979FF)),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sent ${tx.asset}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      '−${amtFmt.format(tx.amount)} ${tx.asset}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tx.to,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
                if (tx.txHash != null && tx.txHash!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 10, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tx.txHash!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(tx.timestamp),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}
