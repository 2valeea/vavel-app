import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/strings.dart';

export '../l10n/strings.dart' show S;

const _kLocaleKey = 'app_locale';
const _storage = FlutterSecureStorage();

/// Persisted locale — defaults to English on first launch.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _kLocaleKey);
    if (saved != null) state = Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: _kLocaleKey, value: locale.languageCode);
  }
}

/// Provides the current [S] translation object derived from [localeProvider].
final stringsProvider = Provider<S>((ref) {
  return S(ref.watch(localeProvider));
});
