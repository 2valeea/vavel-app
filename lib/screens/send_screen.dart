import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_book_entry.dart';
import '../providers/address_book_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/portfolio_provider.dart'
    show kErc20TransferGasLimit, kEthTransferGasLimit;
import '../providers/sent_recipients_provider.dart';
import '../providers/tx_history_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart' show EthereumSendGasOptions;
import '../utils/sensitive_action_auth.dart';
import '../widgets/ethereum_send_gas_card.dart';
import '../models/asset_id.dart';

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
  EthereumSendGasOptions? _evmGas;
  String? _evmGasBlockReason;

  void _onEvmGasChanged(EthereumSendGasOptions? options, String? blockReason) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _evmGas = options;
        _evmGasBlockReason = blockReason;
      });
    });
  }

  @override
  void dispose() {
    _toController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickFromAddressBook() async {
    final book = ref.read(addressBookProvider).valueOrNull ?? [];
    final forAsset = addressBookForAsset(book, widget.assetId);
    if (!mounted) return;
    if (forAsset.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No saved ${widget.assetId.ticker} contacts. Add some in Settings → Address book.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picked = await showModalBottomSheet<AddressBookEntry>(
      context: context,
      backgroundColor: const Color(0xFF172434),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose contact',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            for (final e in forAsset)
              ListTile(
                title: Text(e.label),
                subtitle: Text(
                  e.address,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                onTap: () => Navigator.pop(ctx, e),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _toController.text = picked.address);
    }
  }

  Future<void> _send() async {
    final toInput = _toController.text.trim();
    final amountStr = _amountController.text.trim();
    if (toInput.isEmpty || amountStr.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if ((widget.assetId == AssetId.eth || widget.assetId == AssetId.vavel) &&
        (_evmGasBlockReason != null && _evmGasBlockReason!.isNotEmpty)) {
      setState(() => _error = _evmGasBlockReason);
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Invalid amount.');
      return;
    }

    var toResolved = toInput;
    if (widget.assetId == AssetId.eth || widget.assetId == AssetId.vavel) {
      try {
        toResolved = await ref
            .read(walletServiceProvider)
            .resolveEthereumRecipient(toInput);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = _formatRecipientError(e));
        return;
      }
    }

    final sentBefore = await ref
        .read(sentRecipientsProvider.notifier)
        .hasSentTo(widget.assetId, toResolved);
    if (!sentBefore && mounted) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2A3E),
          title: const Text('New recipient'),
          content: SelectableText(
            'You have not sent ${widget.assetId.ticker} to this address before.\n\n'
            '$toInput'
            '${toInput != toResolved ? '\n\nResolves to:\n$toResolved' : ''}\n\n'
            'Double-check before continuing.',
            style: const TextStyle(height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (go != true) return;
    }

    if (!mounted) return;
    if (!await ensureSensitiveActionAuthenticated(
      context,
      biometricReason: 'Confirm sending ${widget.assetId.ticker}',
    )) {
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _txHash = null;
    });

    try {
      await _performSend(toResolved, amount, amountStr);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatRecipientError(Object e) {
    final s = e.toString();
    const p = 'Bad state: ';
    if (s.startsWith(p)) return s.substring(p.length);
    return s;
  }

  Future<void> _performSend(String to, double amount, String amountStr) async {
    final service = ref.read(walletServiceProvider);
    String? hash;
    switch (widget.assetId) {
      case AssetId.sol:
        hash = await service.sendSolana(to, amount);
      case AssetId.ton:
        await service.sendTon(to, amountStr);
        hash = 'sent';
      case AssetId.eth:
        hash = await service.sendEthereum(to, amount, gas: _evmGas);
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
        hash = await service.sendVavel(to, amount, gas: _evmGas);
      case AssetId.btc:
        hash = await service.sendBitcoin(to, amount);
    }
    if (mounted) setState(() => _txHash = hash);
    await ref.read(txHistoryProvider.notifier).add(TxRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          asset: widget.assetId.ticker,
          to: to,
          amount: amount,
          txHash: hash != 'sent' ? hash : null,
          timestamp: DateTime.now(),
        ));
    await ref.read(sentRecipientsProvider.notifier).markSent(widget.assetId, to);
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
              Row(
                children: [
                  const Expanded(child: _SectionLabel('Recipient Address')),
                  TextButton.icon(
                    onPressed: _pickFromAddressBook,
                    icon: const Icon(Icons.contact_mail_outlined, size: 18),
                    label: const Text('Contacts'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _WalletTextField(
                controller: _toController,
                hint: (id == AssetId.eth || id == AssetId.vavel)
                    ? '0x… or name.eth'
                    : 'Enter ${id.ticker} address',
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

              if (id == AssetId.eth || id == AssetId.vavel) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A3E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.25),
                    ),
                  ),
                  child: EthereumSendGasCard(
                    defaultGasLimit: id == AssetId.eth
                        ? kEthTransferGasLimit
                        : kErc20TransferGasLimit,
                    onGasChanged: _onEvmGasChanged,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              if ((id == AssetId.eth || id == AssetId.vavel) &&
                  _evmGasBlockReason != null &&
                  _evmGasBlockReason!.isNotEmpty) ...[
                Text(
                  _evmGasBlockReason!,
                  style: TextStyle(
                    color: Colors.orangeAccent.shade200,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                onPressed: (_sending ||
                        ((id == AssetId.eth || id == AssetId.vavel) &&
                            (_evmGasBlockReason != null &&
                                _evmGasBlockReason!.isNotEmpty)))
                    ? null
                    : _send,
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

