import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:web3dart/web3dart.dart';

class EthereumKeyPair {
  final EthPrivateKey privateKey;
  final String address; // checksummed hex

  const EthereumKeyPair({required this.privateKey, required this.address});
}

EthereumKeyPair ethereumKeypairFromSeed(List<int> seed) {
  final bip44 = Bip44.fromSeed(
    Uint8List.fromList(seed),
    Bip44Coins.ethereum,
  );
  final account = bip44.purpose.coin
      .account(0)
      .change(Bip44Changes.chainExt)
      .addressIndex(0);

  final rawPrivKey = account.privateKey.raw;
  final ethPrivKey = EthPrivateKey(Uint8List.fromList(rawPrivKey));
  final address = ethPrivKey.address.eip55With0x;
  return EthereumKeyPair(privateKey: ethPrivKey, address: address);
}
