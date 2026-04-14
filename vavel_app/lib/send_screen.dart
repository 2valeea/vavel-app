import 'package:flutter/material.dart';

/// Send flow screen — prefers [const] for every subtree that does not depend
/// on runtime state (see `prefer_const_constructors`).
class SendScreen extends StatelessWidget {
  const SendScreen({
    super.key,
    this.recipientHint = '',
  });

  /// Optional placeholder for last recipient / clipboard.
  final String recipientHint;

  static const EdgeInsets _pagePadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send'),
      ),
      body: SingleChildScrollView(
        padding: SendScreen._pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _RecipientField(hint: recipientHint),
            const SizedBox(height: 16),
            const _AmountField(),
            const SizedBox(height: 24),
            _SubmitRow(onCancel: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }
}

class _RecipientField extends StatelessWidget {
  const _RecipientField({this.hint = ''});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Recipient',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint.isEmpty ? 'Address or ENS' : hint,
          ),
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Amount',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        _AmountTextField(),
      ],
    );
  }
}

class _AmountTextField extends StatelessWidget {
  const _AmountTextField();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: '0.00',
        suffixText: 'ETH',
      ),
    );
  }
}

class _SubmitRow extends StatelessWidget {
  const _SubmitRow({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review tapped (stub).')),
              );
            },
            child: const Text('Review'),
          ),
        ),
      ],
    );
  }
}
