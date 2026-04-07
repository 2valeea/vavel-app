import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// TON keypair derived from a BIP39 mnemonic phrase.
class TonKeyPair {
  /// 32-byte Ed25519 seed (private key material).
  final List<int> privateKey;

  /// 32-byte Ed25519 public key.
  final List<int> publicKey;

  const TonKeyPair({required this.privateKey, required this.publicKey});
}

/// Equivalent of `@ton/crypto` `mnemonicToPrivateKey(words)`.
///
/// Algorithm:
///   1. Join words with a single space.
///   2. PBKDF2-HMAC-SHA512(password=phrase, salt="TON default seed",
///      iterations=100 000, dkLen=64).
///   3. Use the first 32 bytes as the Ed25519 seed.
///   4. Derive the Ed25519 public key from that seed.
Future<TonKeyPair> tonKeypairFromMnemonic(String mnemonic) async {
  final words = mnemonic.trim().split(RegExp(r'\s+'));
  final phrase = words.join(' ');

  // PBKDF2-HMAC-SHA512 — identical to @ton/crypto internals
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha512(),
    iterations: 100000,
    bits: 512, // 64 bytes
  );

  final derivedKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(phrase)),
    nonce: utf8.encode('TON default seed'),
  );

  final keyBytes = await derivedKey.extractBytes(); // 64 bytes
  final seed = keyBytes.sublist(0, 32);

  // Ed25519 keypair from seed
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(seed);
  final publicKeyObj = await keyPair.extractPublicKey();

  return TonKeyPair(
    privateKey: seed,
    publicKey: publicKeyObj.bytes,
  );
}
