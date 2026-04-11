import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';

/// Placeholder Terms of Service for store submission — replace with final counsel-approved text.
class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return _LegalScaffold(
      title: s.legalTermsTitle,
      sections: const [
        _LegalSection(
          heading: '1. Agreement',
          body:
              'By using Vavel Wallet (“the App”), you agree to these Terms of Service. '
              'If you do not agree, do not use the App. This is placeholder text and will be replaced before public release.',
        ),
        _LegalSection(
          heading: '2. Non-custodial wallet',
          body:
              'The App is a non-custodial wallet. You alone control your keys and assets. '
              'We do not have access to your seed phrase, private keys, or funds. Lost credentials cannot be recovered by us.',
        ),
        _LegalSection(
          heading: '3. Risks',
          body:
              'Digital assets involve significant risk, including loss of value, smart contract bugs, '
              'network failures, and user error. You are responsible for verifying addresses, networks, and transactions.',
        ),
        _LegalSection(
          heading: '4. Third-party services',
          body:
              'The App may interact with third-party blockchains, RPC providers, and dApps. '
              'We are not responsible for their availability, behavior, or content.',
        ),
        _LegalSection(
          heading: '5. Placeholder',
          body:
              'Final terms, governing law, dispute resolution, and contact information will be added '
              'prior to app store distribution. Consult legal counsel before publishing.',
        ),
      ],
    );
  }
}

/// Placeholder Privacy Policy for store submission — replace with final counsel-approved text.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return _LegalScaffold(
      title: s.legalPrivacyTitle,
      sections: const [
        _LegalSection(
          heading: '1. Overview',
          body:
              'This Privacy Policy describes how Vavel Wallet (“we”, “us”) handles information when you use the App. '
              'This document is a placeholder and will be finalized before store release.',
        ),
        _LegalSection(
          heading: '2. Data on your device',
          body:
              'Sensitive data such as keys and seed phrases are stored on your device using platform secure storage. '
              'We do not receive or store your private keys or seed phrase on our servers.',
        ),
        _LegalSection(
          heading: '3. Network and analytics',
          body:
              'The App connects to blockchain nodes and may use third-party RPC endpoints you configure. '
              'Optional analytics, crash reporting, or push services (if enabled) will be described in the final policy.',
        ),
        _LegalSection(
          heading: '4. Your choices',
          body:
              'You can stop using the App at any time. You may clear local data through device and in-app settings where available.',
        ),
        _LegalSection(
          heading: '5. Placeholder',
          body:
              'Final sections on data retention, children’s privacy, international transfers, and contact details '
              'will be added before distribution. Consult legal counsel before publishing.',
        ),
      ],
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

class _LegalScaffold extends StatelessWidget {
  const _LegalScaffold({
    required this.title,
    required this.sections,
  });

  final String title;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'Draft placeholder — replace with final legal text before app store submission.',
              style: TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...sections.expand((sec) => [
                Text(
                  sec.heading,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  sec.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
        ],
      ),
    );
  }
}
