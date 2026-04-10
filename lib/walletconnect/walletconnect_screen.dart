import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../crypto/ethereum_keypair.dart';
import 'walletconnect_service.dart';

class WalletConnectScreen extends StatefulWidget {
  final EthereumKeyPair keyPair;
  const WalletConnectScreen({super.key, required this.keyPair});

  @override
  State<WalletConnectScreen> createState() => _WalletConnectScreenState();
}

class _WalletConnectScreenState extends State<WalletConnectScreen> {
  late final WalletConnectService wcService;
  String? wcUri;
  String? status;

  @override
  void initState() {
    super.initState();
    wcService = WalletConnectService(keyPair: widget.keyPair);
    wcService.connector.on('display_uri', (uri) {
      setState(() {
        wcUri = uri;
        status = 'Сканируйте QR-код в dApp';
      });
    });
    wcService.listen();
  }

  Future<void> connect() async {
    setState(() {
      status = 'Ожидание подключения...';
    });
    await wcService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WalletConnect')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: connect,
              child: const Text('Подключиться к dApp'),
            ),
            if (wcUri != null) ...[
              const SizedBox(height: 24),
              QrImageView(
                data: wcUri!,
                size: 220.0,
              ),
              const SizedBox(height: 16),
              Text(status ?? '',
                  style: const TextStyle(color: Colors.greenAccent)),
            ],
          ],
        ),
      ),
    );
  }
}
