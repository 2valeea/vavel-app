import 'package:flutter/material.dart';

class DappConnectScreen extends StatefulWidget {
  const DappConnectScreen({super.key});

  @override
  State<DappConnectScreen> createState() => _DappConnectScreenState();
}

class _DappConnectScreenState extends State<DappConnectScreen> {
  String? _uri;
  String _status = 'Ожидание подключения...';

  @override
  void initState() {
    super.initState();
    _status = 'Готово к подключению dApp';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подключение к dApp')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _uri = 'wc:vavel-demo@2?relay-protocol=irn&symKey=demo';
                  _status = 'Скопируйте URI и откройте его в совместимом dApp';
                });
              },
              child: const Text('Сгенерировать QR для подключения'),
            ),
            if (_uri != null) ...[
              const SizedBox(height: 16),
              SelectableText(_uri!),
            ]
          ],
        ),
      ),
    );
  }
}
