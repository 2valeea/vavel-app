import 'package:web3dart/web3dart.dart';
import 'dart:typed_data';
import 'package:wallet/wallet.dart';
import '../crypto/ethereum_keypair.dart';
import 'oneinch_api.dart';

class DexSwapService {
  final Web3Client web3client;
  final OneInchApi oneInchApi;

  DexSwapService({required this.web3client, required this.oneInchApi});

  Future<String> swapTokens({
    required EthereumKeyPair keyPair,
    required String fromTokenAddress,
    required String toTokenAddress,
    required BigInt amount,
    double slippage = 1.0,
  }) async {
    // Получаем swap-транзакцию от 1inch
    final swapTx = await oneInchApi.getSwapTx(
      fromTokenAddress: fromTokenAddress,
      toTokenAddress: toTokenAddress,
      amount: amount.toString(),
      fromAddress: keyPair.address,
      slippage: slippage.toString(),
    );

    final tx = swapTx['tx'];
    final to = tx['to'] as String;
    final data = tx['data'] as String;
    final value = BigInt.parse(tx['value'] as String);
    final gas = int.tryParse(tx['gas']?.toString() ?? '0');
    final gasPrice =
        tx['gasPrice'] != null ? BigInt.parse(tx['gasPrice']) : null;

    final transaction = Transaction(
      to: EthereumAddress.fromHex(to),
      data: Uint8List.fromList(hexToBytes(data)),
      value: EtherAmount.inWei(value),
      gasPrice: gasPrice != null ? EtherAmount.inWei(gasPrice) : null,
      maxGas: gas,
    );

    // Подписываем и отправляем транзакцию
    final txHash = await web3client.sendTransaction(
      keyPair.privateKey,
      transaction,
      chainId: 1, // Ethereum Mainnet
    );
    return txHash;
  }

  List<int> hexToBytes(String hex) {
    hex = hex.replaceFirst('0x', '');
    return [
      for (int i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ];
  }
}
