import 'package:bip39_mnemonic/bip39_mnemonic.dart';

Future<String> generateMnemonic([int words = 12]) async {
  final length = words == 24 ? MnemonicLength.words24 : MnemonicLength.words12;
  final mnemonic = Mnemonic.generate(
    Language.english,
    length: length,
  );
  return mnemonic.sentence;
}

bool validateMnemonic(String mnemonic) {
  try {
    Mnemonic.fromSentence(mnemonic.trim(), Language.english);
    return true;
  } catch (_) {
    return false;
  }
}

List<int> mnemonicToSeed(String mnemonic) =>
    Mnemonic.fromSentence(mnemonic.trim(), Language.english).seed;
