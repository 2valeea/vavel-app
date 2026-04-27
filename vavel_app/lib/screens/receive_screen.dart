import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'home_screen.dart' show AssetId, AssetInfo;

class ReceiveScreen extends StatelessWidget {
  final AssetId assetId;
  final String address;

  const ReceiveScreen(
      {super.key, required this.assetId, required this.address});

  @override
  Widget build(BuildContext context) {
    final id = assetId;
    final hasAddress = address.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Receive ${id.ticker}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Network badge
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: id.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(id.icon, size: 16, color: id.color),
                      const SizedBox(width: 6),
                      Text(id.label,
                          style: TextStyle(
                              color: id.color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // QR code
              Center(
                child: hasAddress
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: address,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : const SizedBox(
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Hint
              Text(
                'Send only ${id.ticker}${id == AssetId.tiktok ? ' (SPL Token-2022 on Solana, same address as SOL)' : id == AssetId.vaval ? ' (ERC-20 on Ethereum, same address as ETH)' : ''} to this address. '
                'Sending other assets may result in permanent loss.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Address box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  hasAddress ? address : 'Loading…',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 16),

              // Copy button
              ElevatedButton.icon(
                onPressed: hasAddress
                    ? () {
                        Clipboard.setData(ClipboardData(text: address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Address copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: id.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
