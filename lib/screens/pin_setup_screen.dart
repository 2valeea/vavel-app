import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PinSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PinSetupScreen({super.key, required this.onComplete});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pin1 = ValueNotifier<String>('');
  final _pin2 = ValueNotifier<String>('');
  bool _confirming = false;
  bool _loading = false;
  String? _error;

  Future<void> _onPinEntered(String pin) async {
    if (!_confirming) {
      _pin1.value = pin;
      setState(() => _confirming = true);
    } else {
      _pin2.value = pin;
      if (_pin1.value != _pin2.value) {
        setState(() {
          _confirming = false;
          _error = 'PINs do not match. Try again.';
        });
        _pin1.value = '';
        _pin2.value = '';
        return;
      }
      setState(() => _loading = true);
      try {
        await AuthService.setupPin(_pin1.value);
        widget.onComplete();
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_confirming ? 'Confirm PIN' : 'Set PIN'),
        centerTitle: true,
        automaticallyImplyLeading: !_confirming,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : PinPad(
                title: _confirming
                    ? 'Confirm your 6-digit PIN'
                    : 'Create a 6-digit PIN',
                subtitle: _error,
                onComplete: _onPinEntered,
              ),
      ),
    );
  }
}

// ── Shared PIN pad widget ─────────────────────────────────────────────────

class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final void Function(String pin) onComplete;
  const PinPad(
      {super.key,
      required this.title,
      this.subtitle,
      required this.onComplete});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _input = '';

  void _add(String d) {
    if (_input.length >= 6) return;
    setState(() => _input += d);
    if (_input.length == 6) {
      final completed = _input;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() => _input = '');
        widget.onComplete(completed);
      });
    }
  }

  void _del() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (widget.subtitle != null)
          Text(widget.subtitle!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _input.length
                    ? const Color(0xFF2979FF)
                    : const Color(0xFF1A2A3E),
                border: Border.all(color: const Color(0xFF2979FF)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((d) {
                if (d.isEmpty) return const SizedBox(width: 80);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DialButton(
                    label: d,
                    onTap: d == '⌫' ? _del : () => _add(d),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class DialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DialButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1A2A3E),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
