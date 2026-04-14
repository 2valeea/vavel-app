import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enables platform screenshot / screen-recording protection while active.
///
/// Android: [WindowManager.LayoutParams.FLAG_SECURE].
/// Other platforms: no-op for now (iOS cannot block screenshots in a compliant way;
/// recording detection would be a separate pass).
class SecureWindow {
  SecureWindow._();

  static const _channel = MethodChannel('com.vavel.vavel_wallet/secure_window');

  static int _depth = 0;

  static Future<void> pushSecure() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _depth++;
    if (_depth == 1) {
      try {
        await _channel.invokeMethod<void>('setSecure', true);
      } catch (_) {
        _depth--;
      }
    }
  }

  static Future<void> popSecure() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_depth > 0) _depth--;
    if (_depth == 0) {
      try {
        await _channel.invokeMethod<void>('setSecure', false);
      } catch (_) {}
    }
  }
}
