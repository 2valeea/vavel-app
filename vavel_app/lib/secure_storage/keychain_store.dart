import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Injectable secure-storage wrapper for the BIP39 mnemonic.
///
/// On Android, the underlying store uses Android Keystore-backed
/// EncryptedSharedPreferences.  On iOS it targets the Secure Enclave
/// via the system Keychain.
///
/// Obtain the app-wide singleton via `seedStoreProvider`.
class SeedStore {
  static const _kMnemonicKey = 'wallet_mnemonic';
  final FlutterSecureStorage _storage;

  const SeedStore(this._storage);

  /// Persists [mnemonic] (trimmed) to secure storage.
  Future<void> saveMnemonic(String mnemonic) =>
      _storage.write(key: _kMnemonicKey, value: mnemonic.trim());

  /// Returns the stored mnemonic, or `null` if none exists.
  Future<String?> getMnemonic() => _storage.read(key: _kMnemonicKey);

  /// Deletes the stored mnemonic (wallet wipe).
  Future<void> clear() => _storage.delete(key: _kMnemonicKey);

  /// Returns `true` when a non-empty mnemonic has been persisted.
  Future<bool> hasMnemonic() async {
    final val = await _storage.read(key: _kMnemonicKey);
    return val != null && val.isNotEmpty;
  }
}
