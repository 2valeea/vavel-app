import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../providers/locale_provider.dart';

const _kSupportMessagesKey = 'support_messages';
const _storage = FlutterSecureStorage();

/// A single user-composed support message.
class _SupportMessage {
  final String name;
  final String subject;
  final String body;
  final DateTime sentAt;

  const _SupportMessage({
    required this.name,
    required this.subject,
    required this.body,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'subject': subject,
        'body': body,
        'sentAt': sentAt.toIso8601String(),
      };

  factory _SupportMessage.fromJson(Map<String, dynamic> j) => _SupportMessage(
        name: j['name'] as String,
        subject: j['subject'] as String,
        body: j['body'] as String,
        sentAt: DateTime.parse(j['sentAt'] as String),
      );
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<_SupportMessage> _messages = [];
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final raw = await _storage.read(key: _kSupportMessagesKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => _SupportMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _messages = list);
    } catch (_) {
      await _storage.delete(key: _kSupportMessagesKey);
    }
  }

  Future<void> _saveMessage(_SupportMessage msg) async {
    final updated = [msg, ..._messages];
    await _storage.write(
      key: _kSupportMessagesKey,
      value: jsonEncode(updated.map((m) => m.toJson()).toList()),
    );
    if (mounted) setState(() => _messages = updated);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final msg = _SupportMessage(
      name: _nameCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      sentAt: DateTime.now(),
    );
    await _saveMessage(msg);
    _nameCtrl.clear();
    _subjectCtrl.clear();
    _bodyCtrl.clear();
    if (mounted) {
      setState(() {
        _sending = false;
        _sent = true;
      });
    }
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _sent = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final dateFmt = DateFormat('dd MMM yyyy · HH:mm');
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.supportTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Contact info card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2A3E), Color(0xFF0D1B2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: accent.withValues(alpha: 0.35), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: accent),
                      const SizedBox(width: 10),
                      Text(
                        s.support,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.supportDesc,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const _ContactRow(
                    icon: Icons.telegram,
                    label: 'Telegram',
                    value: '@VavelSupport',
                    color: Color(0xFF0088CC),
                  ),
                  const SizedBox(height: 6),
                  const _ContactRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'support@vavel.io',
                    color: Color(0xFF2979FF),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Compose form ────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldLabel(s.supportNameLabel),
                  const SizedBox(height: 6),
                  _SupportField(
                    controller: _nameCtrl,
                    hint: s.supportNameLabel,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '${s.supportNameLabel} required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel(s.supportSubjectLabel),
                  const SizedBox(height: 6),
                  _SupportField(
                    controller: _subjectCtrl,
                    hint: s.supportSubjectLabel,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '${s.supportSubjectLabel} required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel(s.supportMessageLabel),
                  const SizedBox(height: 6),
                  _SupportField(
                    controller: _bodyCtrl,
                    hint: s.supportMessageLabel,
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '${s.supportMessageLabel} required'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  if (_sent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.supportSentConfirm,
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  if (_sent) const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(s.supportSendButton),
                  ),
                ],
              ),
            ),

            // ── Previous messages ───────────────────────────────────────
            if (_messages.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                s.supportPreviousMessages.toUpperCase(),
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              ..._messages.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MessageCard(message: m, dateFmt: dateFmt),
                  )),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
      );
}

class _SupportField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _SupportField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: const Color(0xFF1A2A3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.redAccent.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final _SupportMessage message;
  final DateFormat dateFmt;

  const _MessageCard({required this.message, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message.subject,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                dateFmt.format(message.sentAt),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            message.name,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            message.body,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
