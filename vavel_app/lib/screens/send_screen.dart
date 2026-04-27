import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_book_entry.dart';
import '../providers/address_book_provider.dart';
import '../providers/sent_recipients_provider.dart';
import '../providers/tx_history_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/portfolio_provider.dart';
import '../services/wallet_service.dart' show EthereumSendGasOptions;
import '../utils/sensitive_action_auth.dart';
import '../models/asset_id.dart';
import '../widgets/ethereum_send_gas_card.dart';
import '../navigation/premium_page_route.dart';
import 'address_book_screen.dart';

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
  final _toFocus = FocusNode();
  final _amountFocus = FocusNode();
  bool _sending = false;
  String? _error;
  String? _txHash;
  EthereumSendGasOptions? _evmGas;
  String? _evmGasBlockReason;
  bool _evmGasSeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_evmGasSeeded) return;
    final id = widget.assetId;
    if (id == AssetId.eth || id == AssetId.vaval) {
      _evmGasSeeded = true;
      _evmGas = EthereumSendGasOptions(
        gasLimit:
            id == AssetId.eth ? kEthTransferGasLimit : kErc20TransferGasLimit,
      );
    }
  }

  @override
  void dispose() {
    _toFocus.dispose();
    _amountFocus.dispose();
    _toController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pasteRecipientAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text?.trim();
    if (t == null || t.isEmpty || !mounted) return;
    setState(() {
      _toController.text = t;
      _toController.selection = TextSelection.collapsed(offset: t.length);
    });
    _toFocus.requestFocus();
  }

  Future<void> _pickFromAddressBook() async {
    final book = ref.read(addressBookProvider).valueOrNull ?? [];
    final forAsset = addressBookForAsset(book, widget.assetId);
    if (!mounted) return;
    if (forAsset.isEmpty) {
      await pushPremium(context, const AddressBookScreen());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add a ${widget.assetId.ticker} contact here, then tap Contacts again on Send.',
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
    if (widget.assetId == AssetId.tiktok) {
      setState(() {
        _error =
            'Отправка токена tik-tok (pump.fun, Token-2022) в этом приложении ещё не подключена. '
            'Скопируйте Solana-адрес на экране «Получить» и используйте кошелёк с поддержкой Token-2022.';
      });
      return;
    }
    if (toInput.isEmpty || amountStr.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Invalid amount.');
      return;
    }

    if ((widget.assetId == AssetId.eth || widget.assetId == AssetId.vaval) &&
        (_evmGasBlockReason != null && _evmGasBlockReason!.isNotEmpty)) {
      setState(() => _error = _evmGasBlockReason);
      return;
    }

    var toResolved = toInput;
    if (widget.assetId == AssetId.eth || widget.assetId == AssetId.vaval) {
      try {
        toResolved = await ref
            .read(walletServiceProvider)
            .resolveEthereumRecipient(toInput);
      } catch (e) {
        setState(() => _error = e.toString());
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
            '$toInput\n\n'
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

  Future<void> _performSend(String to, double amount, String amountStr) async {
    final service = ref.read(walletServiceProvider);
    String? hash;
    switch (widget.assetId) {
      case AssetId.tiktok:
        throw StateError('tik-tok: send is handled before _performSend');
      case AssetId.sol:
        hash = await service.sendSolana(to, amount);
        break;
      case AssetId.ton:
        await service.sendTon(to, amountStr);
        hash = 'sent';
        break;
      case AssetId.eth:
        hash = await service.sendEthereum(to, amount, gas: _evmGas);
        break;
      case AssetId.vaval:
        hash = await service.sendVaval(to, amount, gas: _evmGas);
        break;
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
    await ref
        .read(sentRecipientsProvider.notifier)
        .markSent(widget.assetId, to);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.assetId;
    final s = ref.watch(stringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Send ${id.ticker}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.sendFeeDisclosure,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (id == AssetId.eth || id == AssetId.vaval) ...[
                  EthereumSendGasCard(
                    defaultGasLimit: id == AssetId.eth
                        ? kEthTransferGasLimit
                        : kErc20TransferGasLimit,
                    onGasChanged: (options, blockReason) {
                      setState(() {
                        _evmGas = options;
                        _evmGasBlockReason = blockReason;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.sendFeeLineNetwork,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.sendFeeSmallTransferNote,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _SectionLabel('Recipient Address'),
                    TextButton.icon(
                      onPressed: _pasteRecipientAddress,
                      icon: const Icon(Icons.content_paste_go_outlined, size: 18),
                      label: const Text('Paste'),
                    ),
                    TextButton.icon(
                      onPressed: _pickFromAddressBook,
                      icon: const Icon(Icons.contact_mail_outlined, size: 18),
                      label: const Text('Contacts'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _WalletTextField(
                  focusNode: _toFocus,
                  controller: _toController,
                  hint: (id == AssetId.eth || id == AssetId.vaval)
                      ? '0x… or name.eth'
                      : 'Enter ${id.ticker} address',
                  showPasteButton: true,
                ),
                const SizedBox(height: 20),
                _SectionLabel('Amount (${id.ticker})'),
                const SizedBox(height: 6),
                _WalletTextField(
                  focusNode: _amountFocus,
                  controller: _amountController,
                  hint: '0.00',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 12),
                ],
                if (_txHash != null && _txHash != 'sent') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4)),
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
                  onPressed: _sending ||
                          ((id == AssetId.eth || id == AssetId.vaval) &&
                              (_evmGasBlockReason != null &&
                                  _evmGasBlockReason!.isNotEmpty))
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
  final FocusNode? focusNode;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool showPasteButton;

  const _WalletTextField({
    this.focusNode,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.showPasteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    const fill = Color(0xFF1A2A3E);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        enabled: true,
        readOnly: false,
        canRequestFocus: true,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        scrollPadding: const EdgeInsets.only(bottom: 120, top: 24),
        cursorColor: const Color(0xFF2979FF),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF2979FF), width: 1.5),
          ),
          suffixIcon: showPasteButton
              ? IconButton(
                  tooltip: 'Paste',
                  icon: const Icon(Icons.content_paste_go_outlined,
                      color: Colors.white54),
                  onPressed: () async {
                    final data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    final t = data?.text?.trim();
                    if (t == null || t.isEmpty) return;
                    controller.text = t;
                    controller.selection =
                        TextSelection.collapsed(offset: t.length);
                    focusNode?.requestFocus();
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
