import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _pinKey = 'wallet_pin_hash';
  static const _biometricEnabledKey = 'biometric_enabled';
  static final _localAuth = LocalAuthentication();

  // ── PIN ───────────────────────────────────────────────────────────────────

  static Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> setupPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hash);
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  static Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  static String _hashPin(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  // ── Biometrics ────────────────────────────────────────────────────────────

  static Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  static Future<bool> isBiometricEnabled() async {
    if (kIsWeb) return false;
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    if (kIsWeb) return;
    await _storage.write(
        key: _biometricEnabledKey, value: enabled ? 'true' : 'false');
  }

  static Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    return _localAuth.authenticate(
      localizedReason: 'Authenticate to access your wallet',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}
