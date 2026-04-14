import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cryptography/cryptography.dart';

import 'mnemonic.dart' as mn;

class SolanaKeyPair {
  final List<int> privateKey;
  final List<int> publicKey;

  const SolanaKeyPair({required this.privateKey, required this.publicKey});

  String get address => Base58Encoder.encode(publicKey);
}

Future<SolanaKeyPair> solanaKeypairFromMnemonic(String mnemonic) async {
  final seed = mn.mnemonicToSeed(mnemonic); // 64 bytes via bip39

  final derived = Bip32Slip10Ed25519.fromSeed(Uint8List.fromList(seed))
      .childKey(Bip32KeyIndex.hardenIndex(44))
      .childKey(Bip32KeyIndex.hardenIndex(501))
      .childKey(Bip32KeyIndex.hardenIndex(0))
      .childKey(Bip32KeyIndex.hardenIndex(0));

  final privateKeyBytes = List<int>.from(derived.privateKey.raw);

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
  final pubKeyObj = await keyPair.extractPublicKey();

  return SolanaKeyPair(
    privateKey: privateKeyBytes,
    publicKey: List<int>.from(pubKeyObj.bytes),
  );
}
