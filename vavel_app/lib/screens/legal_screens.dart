import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';

/// Draft Terms of Service — disclosure-first English for stores; finalize with counsel.
class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return _LegalScaffold(
      title: s.legalTermsTitle,
      sections: const [
        _LegalSection(
          heading: '1. Acceptance and eligibility',
          body:
              'By downloading or using Vavel Wallet (the “App”), you agree to these Terms of Service. If you do not agree, '
              'do not use the App. You represent that you are of legal age in your jurisdiction to use a digital-asset wallet. '
              'The App is not offered where use would violate applicable law. Governing law, dispute venue, and operator contact '
              'must be completed with qualified counsel before commercial distribution.',
        ),
        _LegalSection(
          heading: '2. Non-custodial wallet',
          body:
              'The App is non-custodial: cryptographic keys and seed material are generated and stored on your device using '
              'platform secure storage where available. We do not receive, store, or recover your seed phrase or private keys on '
              'our servers. If you lose access to your device or credentials, we cannot restore your funds.',
        ),
        _LegalSection(
          heading: '3. Risks; no financial or legal advice',
          body:
              'Digital assets are volatile and experimental. You may lose some or all value. Transactions are generally irreversible. '
              'Nothing in the App is investment, tax, or legal advice. You alone decide whether to send assets and at what price; '
              'you must verify addresses, networks, token contracts, and fee estimates before you confirm.',
        ),
        _LegalSection(
          heading: '4. Third-party networks and services',
          body:
              'The App interacts with public blockchains, RPC providers, indexers, WalletConnect-compatible dApps, and other third '
              'parties you may choose. We do not control and are not responsible for their availability, fees, forks, upgrades, '
              'censorship, or malicious behavior.',
        ),
        _LegalSection(
          heading: '5. App service fee (1 VAVEL, EVM)',
          body:
              'When you confirm a send of a supported asset, the App will first submit a separate on-chain EVM transaction that '
              'transfers exactly 1 VAVEL (the project token on the configured network) to the operator wallet '
              '0xebeaba868348cec64a2712c7d23936af919b09e2. This is a fixed in-app service fee for use of the send flow, distinct '
              'from blockchain network fees. If your VAVEL balance is below 1 VAVEL, the send will not proceed. Because the fee '
              'is fixed, it may represent a high percentage of very small transfers; you should review totals before you confirm. '
              'By confirming, you authorize this fee transaction in addition to your main transfer.',
        ),
        _LegalSection(
          heading: '6. Network (miner / validator) fees',
          body:
              'Blockchains impose their own fees (e.g. gas on Ethereum-compatible networks, native fees on other chains). Those '
              'amounts are paid to the network or its validators/miners and are not the same as the 1 VAVEL app service fee. '
              'Network fees vary with congestion, chain rules, and any gas settings you select where applicable.',
        ),
        _LegalSection(
          heading: '7. No warranty; limitation of liability',
          body:
              'The App is provided on an “AS IS” and “AS AVAILABLE” basis without warranties of any kind, whether express or implied, '
              'to the fullest extent permitted by law. To the fullest extent permitted by law, neither the operator nor contributors '
              'are liable for indirect, incidental, special, consequential, or punitive damages, or loss of profits, data, or goodwill, '
              'arising from your use of the App or inability to use it. Some jurisdictions do not allow certain limitations; in those '
              'cases, our liability is limited to the maximum permitted.',
        ),
        _LegalSection(
          heading: '8. Indemnity',
          body:
              'To the extent permitted by law, you agree to indemnify and hold harmless the operator and its contributors from claims, '
              'losses, liabilities, and expenses (including reasonable attorneys’ fees) arising from your misuse of the App, your '
              'violation of these Terms, or your violation of third-party rights.',
        ),
        _LegalSection(
          heading: '9. Changes to these Terms',
          body:
              'We may update these Terms to reflect product, legal, or security changes. Material changes should be communicated in-app '
              'or by other reasonable means where practicable. Continued use after the effective date constitutes acceptance unless '
              'law requires a different process in your region.',
        ),
        _LegalSection(
          heading: '10. Final legal review',
          body:
              'This document is a structured draft for transparency and app store review. Operator identity, registration details, '
              'consumer rights notices required in your country, refund rules where applicable, and signature blocks must be added '
              'by qualified counsel before you rely on it in production.',
        ),
      ],
    );
  }
}

/// Draft Privacy Policy — disclosure-first English for stores; finalize with counsel.
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
              'This Privacy Policy explains how information is handled when you use Vavel Wallet (the “App”). The App is designed '
              'to minimize collection of personal data: keys and seed material stay on your device. This draft must be finalized '
              'with counsel to address local law (including GDPR, UK GDPR, CCPA/CPRA where relevant) before commercial release.',
        ),
        _LegalSection(
          heading: '2. Information stored on your device',
          body:
              'Sensitive data such as seed phrases, private keys, and PIN-related secrets are stored locally using platform secure '
              'storage and OS protections where available. We do not operate a custodial vault that holds your keys on our servers.',
        ),
        _LegalSection(
          heading: '3. Network activity, RPC, push, and analytics',
          body:
              'When you use the App, your device communicates with blockchain nodes and RPC endpoints (including those you configure). '
              'Those providers may log IP addresses and request metadata under their own policies. If you enable push notifications '
              'or crash reporting, the relevant SDK (e.g. Firebase) may process device tokens or diagnostics as described in that '
              'vendor’s documentation; list each SDK and lawful basis in the final policy.',
        ),
        _LegalSection(
          heading: '4. On-chain data and the 1 VAVEL service fee',
          body:
              'Transfers—including the fixed 1 VAVEL service fee to 0xebeaba868348cec64a2712c7d23936af919b09e2 and your main send—are '
              'recorded on public blockchains. That information is not secret: addresses, amounts, and transaction hashes may appear '
              'on explorers indefinitely. Signing occurs in the App on your device; we do not need your seed phrase on our servers '
              'to perform those transactions.',
        ),
        _LegalSection(
          heading: '5. Your choices and retention',
          body:
              'You may stop using the App at any time, revoke push permissions in OS settings, and clear local data where the App '
              'provides controls. Blockchain records cannot be erased by us. Describe concrete retention periods for any server-side '
              'logs (if introduced later) in the final policy.',
        ),
        _LegalSection(
          heading: '6. Children',
          body:
              'The App is not directed at children. We do not knowingly collect personal information from anyone under 13 (or the '
              'higher age required by local law for digital consent). If you believe a child has provided information, contact us '
              'using the contact method your counsel adds to the final policy.',
        ),
        _LegalSection(
          heading: '7. International users and transfers',
          body:
              'Users may access the App from multiple countries. If personal data is processed across borders, the final policy should '
              'identify legal mechanisms (e.g. Standard Contractual Clauses) appropriate to your setup.',
        ),
        _LegalSection(
          heading: '8. Security',
          body:
              'We implement reasonable technical and organizational measures consistent with a non-custodial mobile wallet. No method '
              'of transmission or storage is 100% secure; you accept residual risk.',
        ),
        _LegalSection(
          heading: '9. Your rights and how to contact us',
          body:
              'Depending on your jurisdiction, you may have rights to access, correct, delete, or port personal data we hold about you, '
              'or to object to certain processing. Insert operator contact email, postal address, and data-protection contact in the '
              'final version, plus any required Data Protection Officer details.',
        ),
        _LegalSection(
          heading: '10. Changes to this Policy',
          body:
              'We may update this Policy when the product or law changes. Material updates should be communicated in-app or by other '
              'reasonable means. The “effective date” at the top should be maintained in the final document.',
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
              'Draft for transparency and app store review. Operator legal name, registered address, governing law, '
              'age and consumer notices required in your region, and contact channels must be finalized with qualified '
              'counsel before production release.',
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
