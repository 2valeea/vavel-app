import 'package:flutter/material.dart';
import '../crypto/ethereum_keypair.dart';
import 'dex_swap_service.dart';
import 'oneinch_api.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

class DexSwapScreen extends StatefulWidget {
  final EthereumKeyPair keyPair;
  final String oneInchApiKey;

  const DexSwapScreen(
      {super.key, required this.keyPair, required this.oneInchApiKey});

  @override
  State<DexSwapScreen> createState() => _DexSwapScreenState();
}

class _DexSwapScreenState extends State<DexSwapScreen> {
  late final Web3Client web3client;
  late final OneInchApi oneInchApi;
  late final DexSwapService dexSwapService;

  final fromTokenController = TextEditingController();
  final toTokenController = TextEditingController();
  final amountController = TextEditingController();
  String? txHash;
  String? error;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    web3client = Web3Client('https://eth.llamarpc.com', http.Client());
    oneInchApi = OneInchApi(apiKey: widget.oneInchApiKey);
    dexSwapService =
        DexSwapService(web3client: web3client, oneInchApi: oneInchApi);
  }

  @override
  void dispose() {
    fromTokenController.dispose();
    toTokenController.dispose();
    amountController.dispose();
    web3client.dispose();
    super.dispose();
  }

  Future<void> swap() async {
    setState(() {
      loading = true;
      error = null;
      txHash = null;
    });
    try {
      final hash = await dexSwapService.swapTokens(
        keyPair: widget.keyPair,
        fromTokenAddress: fromTokenController.text.trim(),
        toTokenAddress: toTokenController.text.trim(),
        amount: BigInt.parse(amountController.text.trim()),
      );
      setState(() {
        txHash = hash;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEX Swap (1inch)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: fromTokenController,
              decoration:
                  const InputDecoration(labelText: 'From Token Address'),
            ),
            TextField(
              controller: toTokenController,
              decoration: const InputDecoration(labelText: 'To Token Address'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (wei)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : swap,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Swap'),
            ),
            if (txHash != null) ...[
              const SizedBox(height: 16),
              Text('Tx Hash: $txHash'),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
