import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ethereum_gas_fees.dart';
import '../models/fee_estimate.dart' show FeeEstimationException;
import '../providers/portfolio_provider.dart';
import '../services/wallet_service.dart' show EthereumSendGasOptions;

enum EthGasSpeed { slow, standard, fast, custom }

/// EIP-1559 / legacy gas picker with presets and advanced fields for EVM sends.
class EthereumSendGasCard extends ConsumerStatefulWidget {
  const EthereumSendGasCard({
    super.key,
    required this.defaultGasLimit,
    required this.onGasChanged,
  });

  final int defaultGasLimit;

  /// [blockReason] non-null disables Send until the user fixes gas fields.
  final void Function(EthereumSendGasOptions? options, String? blockReason)
      onGasChanged;

  @override
  ConsumerState<EthereumSendGasCard> createState() =>
      _EthereumSendGasCardState();
}

class _EthereumSendGasCardState extends ConsumerState<EthereumSendGasCard> {
  EthGasSpeed _speed = EthGasSpeed.standard;
  late int _gasLimit;
  final _maxGweiCtrl = TextEditingController();
  final _prioGweiCtrl = TextEditingController();
  final _gasLimitCtrl = TextEditingController();
  bool _advancedOpen = false;
  bool _seeded = false;
  bool _didDepsCallback = false;

  @override
  void initState() {
    super.initState();
    _gasLimit = widget.defaultGasLimit;
    _gasLimitCtrl.text = '$_gasLimit';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didDepsCallback) return;
    _didDepsCallback = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final v = ref.read(ethereumNetworkGasFeesProvider);
      _onFeesAsync(v);
    });
  }

  @override
  void dispose() {
    _maxGweiCtrl.dispose();
    _prioGweiCtrl.dispose();
    _gasLimitCtrl.dispose();
    super.dispose();
  }

  static String _weiToGweiStr(BigInt wei) =>
      (wei.toDouble() / 1e9).toStringAsFixed(2);

  static BigInt? _parseGwei(String raw) {
    final v = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (v == null || v < 0) return null;
    return BigInt.from((v * 1e9).round());
  }

  GasFeeTier? _tierFor(
    EthereumNetworkGasFees fees,
    EthGasSpeed speed,
  ) {
    if (!fees.eip1559 && fees.legacyGasPriceWei != null) {
      final w = fees.legacyGasPriceWei!;
      final m = switch (speed) {
        EthGasSpeed.slow => 0.88,
        EthGasSpeed.standard => 1.0,
        EthGasSpeed.fast => 1.12,
        EthGasSpeed.custom => 1.0,
      };
      final p = BigInt.from((w.toDouble() * m).round());
      return GasFeeTier(maxFeePerGas: p, maxPriorityFeePerGas: p);
    }
    return switch (speed) {
      EthGasSpeed.slow => fees.slow,
      EthGasSpeed.standard => fees.standard,
      EthGasSpeed.fast => fees.fast,
      EthGasSpeed.custom => null,
    };
  }

  void _fillCustomFromTier(GasFeeTier t) {
    _maxGweiCtrl.text = _weiToGweiStr(t.maxFeePerGas);
    _prioGweiCtrl.text = _weiToGweiStr(t.maxPriorityFeePerGas);
  }

  EthereumSendGasOptions? _buildOptions(EthereumNetworkGasFees fees) {
    if (!fees.hasTiers && fees.legacyGasPriceWei == null) return null;

    if (_speed == EthGasSpeed.custom) {
      final maxW = _parseGwei(_maxGweiCtrl.text);
      final prioW = fees.eip1559 ? _parseGwei(_prioGweiCtrl.text) : maxW;
      final gl = int.tryParse(_gasLimitCtrl.text.trim());
      if (maxW == null || prioW == null || gl == null) return null;
      if (fees.eip1559 && maxW < prioW) return null;
      if (gl < 21000 || gl > 3000000) return null;
      if (fees.eip1559) {
        return EthereumSendGasOptions(
          gasLimit: gl,
          maxFeePerGas: maxW,
          maxPriorityFeePerGas: prioW,
        );
      }
      return EthereumSendGasOptions(
        gasLimit: gl,
        legacyGasPriceWei: maxW,
      );
    }

    final tier = _tierFor(fees, _speed);
    if (tier == null) return null;
    final gl = int.tryParse(_gasLimitCtrl.text.trim());
    final limit = gl ?? _gasLimit;
    if (limit < 21000 || limit > 3000000) return null;

    if (fees.eip1559) {
      return EthereumSendGasOptions(
        gasLimit: limit,
        maxFeePerGas: tier.maxFeePerGas,
        maxPriorityFeePerGas: tier.maxPriorityFeePerGas,
      );
    }
    return EthereumSendGasOptions(
      gasLimit: limit,
      legacyGasPriceWei: tier.maxFeePerGas,
    );
  }

  String? _blockReason(EthereumNetworkGasFees fees) {
    final gl = int.tryParse(_gasLimitCtrl.text.trim());
    if (gl != null && (gl < 21000 || gl > 3000000)) {
      return 'Gas limit must be between 21,000 and 3,000,000.';
    }
    if (_speed == EthGasSpeed.custom) {
      if (_parseGwei(_maxGweiCtrl.text) == null) {
        return fees.eip1559
            ? 'Enter a valid max fee (Gwei).'
            : 'Enter a valid gas price (Gwei).';
      }
      if (fees.eip1559 && _parseGwei(_prioGweiCtrl.text) == null) {
        return 'Enter a valid priority fee (Gwei).';
      }
      final a = _parseGwei(_maxGweiCtrl.text);
      final b = _parseGwei(_prioGweiCtrl.text);
      if (fees.eip1559 && a != null && b != null && a < b) {
        return 'Max fee must be ≥ priority fee.';
      }
    }
    return null;
  }

  void _emit(EthereumNetworkGasFees fees) {
    final block = _blockReason(fees);
    final opts = block == null ? _buildOptions(fees) : null;
    widget.onGasChanged(opts, block);
  }

  void _onFeesAsync(AsyncValue<EthereumNetworkGasFees> async) {
    if (!mounted) return;
    if (async.hasError) {
      widget.onGasChanged(null, null);
      return;
    }
    if (!async.hasValue) return;
    final fees = async.requireValue;
    if (!fees.hasTiers && fees.legacyGasPriceWei == null) {
      widget.onGasChanged(null, null);
      return;
    }
    if (!_seeded) {
      _seeded = true;
      final tier = fees.standard ?? fees.slow ?? fees.fast;
      if (tier != null) _fillCustomFromTier(tier);
    } else if (_speed != EthGasSpeed.custom) {
      final tier = _tierFor(fees, _speed);
      if (tier != null) _fillCustomFromTier(tier);
    }
    _emit(fees);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<EthereumNetworkGasFees>>(
      ethereumNetworkGasFeesProvider,
      (prev, next) => _onFeesAsync(next),
    );

    final asyncFees = ref.watch(ethereumNetworkGasFeesProvider);

    return asyncFees.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 10),
            Text('Loading gas prices…',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
      error: (e, _) {
        final msg = e is FeeEstimationException
            ? e.userMessage
            : 'Could not load gas prices.';
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$msg Transaction will use the node’s default gas.',
                  style: const TextStyle(color: Colors.amber, fontSize: 11.5),
                ),
              ),
            ],
          ),
        );
      },
      data: (fees) {
        if (!fees.hasTiers && fees.legacyGasPriceWei == null) {
          return Text(
            'Gas data unavailable. Send will use automatic fees.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          );
        }

        void setSpeed(EthGasSpeed s) {
          setState(() => _speed = s);
          final t = _tierFor(fees, s);
          if (t != null) _fillCustomFromTier(t);
          _emit(fees);
        }

        final tierNow = _tierFor(fees, _speed) ??
            fees.standard ??
            fees.slow ??
            fees.fast;
        final maxFeeWei = _speed == EthGasSpeed.custom
            ? _parseGwei(_maxGweiCtrl.text)
            : tierNow?.maxFeePerGas;
        final glParsed =
            int.tryParse(_gasLimitCtrl.text.trim()) ?? _gasLimit;

        final feePreview = maxFeeWei != null && maxFeeWei > BigInt.zero
            ? ref.watch(
                ethMaxTotalFeeProvider(
                  EthereumMaxFeeArgs(
                    maxFeePerGas: maxFeeWei,
                    gasLimit: glParsed.clamp(21000, 3000000),
                  ),
                ),
              )
            : null;

        final customInvalid = _speed == EthGasSpeed.custom &&
            fees.eip1559 &&
            _parseGwei(_maxGweiCtrl.text) != null &&
            _parseGwei(_prioGweiCtrl.text) != null &&
            _parseGwei(_maxGweiCtrl.text)! < _parseGwei(_prioGweiCtrl.text)!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              fees.eip1559
                  ? 'Network fee (EIP-1559)'
                  : 'Network fee (legacy gas price)',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _speedChip(
                  label: 'Slow',
                  selected: _speed == EthGasSpeed.slow,
                  onTap: () => setSpeed(EthGasSpeed.slow),
                ),
                _speedChip(
                  label: 'Market',
                  selected: _speed == EthGasSpeed.standard,
                  onTap: () => setSpeed(EthGasSpeed.standard),
                ),
                _speedChip(
                  label: 'Fast',
                  selected: _speed == EthGasSpeed.fast,
                  onTap: () => setSpeed(EthGasSpeed.fast),
                ),
                _speedChip(
                  label: 'Custom',
                  selected: _speed == EthGasSpeed.custom,
                  onTap: () {
                    setState(() {
                      _speed = EthGasSpeed.custom;
                      _advancedOpen = true;
                    });
                    _emit(fees);
                  },
                ),
              ],
            ),
            if (feePreview != null) ...[
              const SizedBox(height: 10),
              feePreview.when(
                loading: () => const Text('Estimating USD…',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                error: (_, __) => const SizedBox.shrink(),
                data: (est) => Text(
                  'Max total fee ≈ \$${est.usd.toStringAsFixed(2)} '
                  '(${_formatEthWei(est.nativeAmount)} ETH)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Advanced',
                  style: TextStyle(
                    color: Colors.blueGrey.shade200,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                initiallyExpanded: _advancedOpen,
                onExpansionChanged: (o) => setState(() => _advancedOpen = o),
                children: [
                  if (fees.eip1559) ...[
                    TextField(
                      controller: _prioGweiCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _decoration(
                        'Max priority fee (Gwei)',
                        'Tip to validators',
                      ),
                      onChanged: (_) {
                        setState(() => _speed = EthGasSpeed.custom);
                        _emit(fees);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _maxGweiCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _decoration(
                        'Max fee (Gwei)',
                        'Cap per gas unit',
                      ),
                      onChanged: (_) {
                        setState(() => _speed = EthGasSpeed.custom);
                        _emit(fees);
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: _maxGweiCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _decoration('Gas price (Gwei)', 'Legacy'),
                      onChanged: (_) {
                        setState(() => _speed = EthGasSpeed.custom);
                        _emit(fees);
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gasLimitCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _decoration(
                      'Gas limit',
                      '21000 transfer · ~65000 ERC-20',
                    ),
                    onChanged: (_) => _emit(fees),
                  ),
                  if (customInvalid) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Max fee must be ≥ priority fee.',
                      style: TextStyle(
                          color: Colors.redAccent.shade200, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatEthWei(BigInt wei) =>
      (wei.toDouble() / 1e18).toStringAsFixed(6);

  InputDecoration _decoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: const Color(0xFF152535),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _speedChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? const Color(0xFF2979FF).withValues(alpha: 0.35)
          : const Color(0xFF1A2A3E),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
