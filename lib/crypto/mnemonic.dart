import 'package:bip39/bip39.dart' as bip39;

Future<String> generateMnemonic([int words = 12]) async {
  final strength = words == 24 ? 256 : 128;
  return bip39.generateMnemonic(strength: strength);
}

bool validateMnemonic(String mnemonic) =>
    bip39.validateMnemonic(mnemonic.trim());

List<int> mnemonicToSeed(String mnemonic) =>
    bip39.mnemonicToSeed(mnemonic.trim());
