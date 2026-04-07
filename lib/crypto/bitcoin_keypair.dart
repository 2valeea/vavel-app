import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';

class BitcoinKeyPair {
  final List<int> privateKey;
  final String address; // P2PKH mainnet

  const BitcoinKeyPair({required this.privateKey, required this.address});
}

BitcoinKeyPair bitcoinKeypairFromSeed(List<int> seed) {
  final bip44 = Bip44.fromSeed(
    Uint8List.fromList(seed),
    Bip44Coins.bitcoin,
  );
  final account = bip44.purpose.coin
      .account(0)
      .change(Bip44Changes.chainExt)
      .addressIndex(0);

  final rawPrivKey = List<int>.from(account.privateKey.raw);
  final address = account.publicKey.toAddress;
  return BitcoinKeyPair(privateKey: rawPrivKey, address: address);
}
