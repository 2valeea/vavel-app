import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fee_estimate.dart' show FeeEstimationException;
import '../providers/balance_provider.dart';
import '../providers/portfolio_provider.dart'
    show ethFeeProvider, kEthTransferGasLimit;
import '../providers/tx_history_provider.dart';
import '../providers/wallet_provider.dart';
import 'home_screen.dart' show AssetId, AssetInfo;

class SendScreen extends ConsumerStatefulWidget {
  final AssetId assetId;
  final String address;

  const SendScreen({super.key, required this.assetId, required this.address});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  bool _sending = false;
  String? _error;
  String? _txHash;

  @override
  void dispose() {
    _toController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final to = _toController.text.trim();
    final amountStr = _amountController.text.trim();
    if (to.isEmpty || amountStr.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Invalid amount.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _txHash = null;
    });

    try {
      final service = ref.read(walletServiceProvider);
      String? hash;
      switch (widget.assetId) {
        case AssetId.sol:
          hash = await service.sendSolana(to, amount);
        case AssetId.ton:
          await service.sendTon(to, amountStr);
          hash = 'sent';
        case AssetId.eth:
          hash = await service.sendEthereum(to, amount);
        case AssetId.vavel:
          final balances = ref.read(balanceProvider).valueOrNull;
          final vavelBal = balances?['vavel']?.toDecimal() ?? 0.0;
          final ethBal = balances?['eth']?.toDecimal() ?? 0.0;
          if (amount > vavelBal) {
            setState(() => _error =
                'Insufficient VAVEL balance (available: ${vavelBal.toStringAsFixed(4)} VAVEL).');
            return;
          }
          if (ethBal == 0) {
            setState(() =>
                _error = 'ETH balance required to pay the \$0.03 gas fee.');
            return;
          }
          hash = await service.sendVavel(to, amount);
        case AssetId.btc:
          if (mounted) {
            setState(() =>
                _error = 'BTC send requires full UTXO signing — coming soon.');
          }
          return;
      }
      if (mounted) setState(() => _txHash = hash);
      // Record in local transaction history
      await ref.read(txHistoryProvider.notifier).add(TxRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            asset: widget.assetId.ticker,
            to: to,
            amount: amount,
            txHash: hash != 'sent' ? hash : null,
            timestamp: DateTime.now(),
          ));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.assetId;
    return Scaffold(
      appBar: AppBar(
        title: Text('Send ${id.ticker}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // From
              const _SectionLabel('From'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.address.isEmpty ? '—' : widget.address,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // To
              const _SectionLabel('Recipient Address'),
              const SizedBox(height: 6),
              _WalletTextField(
                controller: _toController,
                hint: 'Enter ${id.ticker} address',
              ),
              const SizedBox(height: 20),

              // Amount
              _SectionLabel('Amount (${id.ticker})'),
              const SizedBox(height: 6),
              _WalletTextField(
                controller: _amountController,
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              if (id == AssetId.eth) ...[
                const SizedBox(height: 8),
                _FeeEstimateWidget(assetId: id),
              ] else if (id == AssetId.vavel) ...[
                const SizedBox(height: 8),
                const _VavelFeeSection(),
              ],
              const SizedBox(height: 32),

              if (_error != null) ...[
                Text(_error!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13)),
                const SizedBox(height: 12),
              ],

              if (_txHash != null && _txHash != 'sent') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaction sent!',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      SelectableText(
                        _txHash!,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'monospace',
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_txHash == 'sent') ...[
                const Text('TON transaction submitted!',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
              ],

              ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(backgroundColor: id.color),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Send ${id.ticker}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5));
  }
}

class _WalletTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _WalletTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A2A3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Fixed $0.03 USD fee card shown for all VAVEL transfers.
class _VavelFeeSection extends StatelessWidget {
  const _VavelFeeSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_gas_station_outlined, size: 14, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network fee: \$0.03',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  'Fixed gas fee · deducted from your ETH balance',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the estimated network fee for ETH transactions.
///
/// Three states:
///   • Loading — small spinner + "Estimating fee…"
///   • Data    — "Network fee: ~$0.42 (0.000012 ETH)"
///   • Error   — amber warning with [FeeEstimationException.userMessage];
///               does NOT block the send button (fee is advisory).
class _FeeEstimateWidget extends ConsumerWidget {
  final AssetId assetId;

  const _FeeEstimateWidget({required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeAsync = ref.watch(ethFeeProvider(kEthTransferGasLimit));

    return feeAsync.when(
      loading: () => const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child:
                CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey),
          ),
          SizedBox(width: 8),
          Text('Estimating fee…',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      data: (fee) => Text(
        'Network fee: ~\$${fee.usd.toStringAsFixed(2)}'
        ' (${(fee.nativeAmount.toDouble() / 1e18).toStringAsFixed(6)} ETH)'
        '\nDeducted from your ETH balance.',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      error: (err, _) {
        final msg = err is FeeEstimationException
            ? err.userMessage
            : 'Fee estimate unavailable. Try again later.';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
