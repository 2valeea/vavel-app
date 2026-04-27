import 'package:flutter/foundation.dart' show
    defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show MethodChannel, MissingPluginException;

/// GMS (FCM) vs HMS (Huawei Push Kit) resolution on Android, derived from
/// [HuaweiApiAvailability] / [GoogleApiAvailability] in native code.
enum MobilePushProviderKind { fcm, hms, none }

const String _kPushChannel = 'com.vavel.official.wallet/push';

/// Which push stack the device can use. iOS always reports [fcm] (APNs via Firebase);
/// use [fcm] as a conservative default when the platform channel is unavailable
/// (e.g. some test environments).
class MobilePushProvider {
  const MobilePushProvider._();

  static const MethodChannel _ch = MethodChannel(_kPushChannel);

  /// Resolves: HMS (Huawei Push) when HMS Core is available, else FCM (Google) when
  /// Play services are available (see [MainActivity] `resolvePushProvider`).
  static Future<MobilePushProviderKind> getKind() async {
    if (kIsWeb) {
      return MobilePushProviderKind.none;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return MobilePushProviderKind.fcm;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return MobilePushProviderKind.none;
    }
    try {
      final s = await _ch.invokeMethod<String>('getProvider');
      switch (s) {
        case 'hms':
          return MobilePushProviderKind.hms;
        case 'fcm':
          return MobilePushProviderKind.fcm;
        case 'none':
          return MobilePushProviderKind.none;
        default:
          return MobilePushProviderKind.fcm;
      }
    } on MissingPluginException {
      return MobilePushProviderKind.fcm;
    }
  }

  static Future<void> requestPostNotificationPermissionIfNeeded() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _ch.invokeMethod<void>('requestPostNotifications');
    } on MissingPluginException {
      // Ignore e.g. desktop.
    }
  }
}
