import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/asset_id.dart';
import '../providers/price_provider.dart';
import '../providers/jupiter_tiktok_provider.dart';
import '../providers/locale_provider.dart';

/// Simple swap/conversion calculator.
///
/// Uses live market prices to show how much of asset B you'd receive for a
/// given amount of asset A.  No on-chain transaction is performed here.
class SwapScreen extends ConsumerStatefulWidget {
  const SwapScreen({super.key});

  @override
  ConsumerState<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends ConsumerState<SwapScreen> {
  AssetId _from = AssetId.eth;
  AssetId _to = AssetId.btc;
  final _amtController = TextEditingController(text: '1');
  final _usdFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final _cryptoFmt = NumberFormat('#,##0.########');

  @override
  void dispose() {
    _amtController.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final pricesAsync = ref.watch(priceProvider);
    final jupTiktok = ref.watch(jupiterTiktokInfoProvider);
    // Never gate the whole screen on HTTP: user must always tap pickers & swap.
    final prices = pricesAsync.valueOrNull ?? <String, double>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(s.swapTitle),
        actions: [
          IconButton(
            tooltip: 'Refresh rates',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(priceProvider);
              ref.invalidate(jupiterTiktokInfoProvider);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pricesAsync.isLoading && prices.isEmpty)
            const LinearProgressIndicator(minHeight: 2),
          if (pricesAsync.hasError)
            Material(
              color: Colors.redAccent.withValues(alpha: 0.12),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_off, color: Colors.redAccent),
                title: Text(
                  s.swapPricesMissing,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  'Выбор валют работает. Нажмите «Обновить» для курсов.',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(priceProvider);
                    ref.invalidate(jupiterTiktokInfoProvider);
                  },
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(priceProvider);
                ref.invalidate(jupiterTiktokInfoProvider);
                try {
                  await ref.read(priceProvider.future);
                } catch (_) {}
                try {
                  await ref.read(jupiterTiktokInfoProvider.future);
                } catch (_) {}
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildBody(
                  context,
                  s,
                  prices,
                  jupTiktok.valueOrNull?.usdPrice,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    s,
    Map<String, double> prices,
    double? tiktokUsd,
  ) {
    final fromPrice = _priceFor(_from, prices, tiktokUsd: tiktokUsd);
    final toPrice = _priceFor(_to, prices, tiktokUsd: tiktokUsd);

    final amountStr = _amtController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountStr) ?? 0;

    final fromUsd = fromPrice != null ? fromPrice * amount : null;
    final result = (fromUsd != null && toPrice != null && toPrice > 0)
        ? fromUsd / toPrice
        : null;

    final rate = (fromPrice != null && toPrice != null && toPrice > 0)
        ? fromPrice / toPrice
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── From ──────────────────────────────────────────────────────
          _SectionLabel(s.swapFrom),
          const SizedBox(height: 8),
          _AssetPickerButton(
            selected: _from,
            exclude: _to,
            onChanged: (id) => setState(() => _from = id),
          ),
          const SizedBox(height: 12),
          _AmountField(
            controller: _amtController,
            asset: _from,
            usdFmt: _usdFmt,
            price: fromPrice,
            onChanged: (_) => setState(() {}),
          ),

          // ── Swap button ───────────────────────────────────────────────
          const SizedBox(height: 16),
          Center(
            child: Material(
              color: const Color(0xFF1A2A3E),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _swap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Ink(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              const Color(0xFF2979FF).withValues(alpha: 0.4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.swap_vert,
                          color: Color(0xFF2979FF), size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── To ────────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _SectionLabel(s.swapTo),
          const SizedBox(height: 8),
          _AssetPickerButton(
            selected: _to,
            exclude: _from,
            onChanged: (id) => setState(() => _to = id),
          ),

          // ── Result ────────────────────────────────────────────────────
          const SizedBox(height: 20),
          _ResultCard(
            label: s.swapResult,
            value: result != null
                ? '${_cryptoFmt.format(result)} ${_to.ticker}'
                : '—',
            subValue: fromUsd != null ? _usdFmt.format(fromUsd) : null,
          ),

          // ── Rate ──────────────────────────────────────────────────────
          if (rate != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              label: s.swapRate,
              value:
                  '1 ${_from.ticker} = ${_cryptoFmt.format(rate)} ${_to.ticker}',
            ),
          ],

          // ── Disclaimer ────────────────────────────────────────────────
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              s.swapNote,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  double? _priceFor(
    AssetId id,
    Map<String, double> prices, {
    double? tiktokUsd,
  }) {
    if (id == AssetId.tiktok) return tiktokUsd;
    return prices[id.ticker];
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

/// Opens a modal list — reliable taps on all devices (unlike nested [DropdownButton]).
class _AssetPickerButton extends StatelessWidget {
  final AssetId selected;
  final AssetId exclude;
  final ValueChanged<AssetId> onChanged;

  const _AssetPickerButton({
    required this.selected,
    required this.exclude,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final options = AssetId.values.where((a) => a != exclude).toList();
    final picked = await showModalBottomSheet<AssetId>(
      context: context,
      backgroundColor: const Color(0xFF172434),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Выберите актив',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            for (final id in options)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: id.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(id.icon, color: id.color, size: 18),
                ),
                title: Text(
                  id.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  id.ticker,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2A3E),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(selected.icon, color: selected.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selected.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Text(
                selected.ticker,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final AssetId asset;
  final NumberFormat usdFmt;
  final double? price;
  final ValueChanged<String> onChanged;

  const _AmountField({
    required this.controller,
    required this.asset,
    required this.usdFmt,
    required this.price,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    final usdValue = price != null ? price! * amount : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF2979FF).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: controller,
                enabled: true,
                readOnly: false,
                canRequestFocus: true,
                onChanged: onChanged,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                cursorColor: const Color(0xFF2979FF),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(
                      fontSize: 22,
                      color: Colors.white.withValues(alpha: 0.2)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(asset.ticker,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              if (usdValue != null)
                Text(usdFmt.format(usdValue),
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;

  const _ResultCard({
    required this.label,
    required this.value,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A3E), Color(0xFF0D1B2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(subValue!,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
