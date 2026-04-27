import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:huawei_push/huawei_push.dart' as hms;

import '../config.dart';
import '../firebase_options.dart';
import '../providers/wallet_provider.dart';
import '../utils/logger.dart';
import 'push_platform.dart';

const _hmsPushTokenScope = '';

/// Must be registered in [main] for FCM before [runApp] (see `lib/main.dart`).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  logger.i('Background FCM: id=${message.messageId} data=${message.data}');
}

const _kNotifyTx = 'notify_tx';

class PushNotificationService {
  static bool _started = false;
  static StreamSubscription<String>? _hmsTokenSub;
  static StreamSubscription<hms.RemoteMessage>? _hmsMessageSub;

  /// Called from [HomeScreen] after unlock when transaction alerts are enabled.
  static Future<void> maybeInitializeAfterUnlock(WidgetRef ref) async {
    if (_started) return;
    if (kIsWeb) return;

    const storage = FlutterSecureStorage();
    final notifyRaw = await storage.read(key: _kNotifyTx);
    final notifyTx = notifyRaw != 'false';
    if (!notifyTx) {
      logger.i('Push: transaction alerts disabled; skip init');
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _initFcm(ref);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final kind = await MobilePushProvider.getKind();
      if (kind == MobilePushProviderKind.hms) {
        await _initHms(ref);
        return;
      }
      if (kind == MobilePushProviderKind.fcm) {
        await _initFcm(ref);
        return;
      }
      logger.w('Push: no FCM or HMS; skip init');
    }
  }

  static Future<void> _initFcm(WidgetRef ref) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e, st) {
      logger.e(
        'Firebase init failed — add google-services.json & run flutterfire configure: $e',
        stackTrace: st,
      );
      return;
    }
    _started = true;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await MobilePushProvider.requestPostNotificationPermissionIfNeeded();
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      logger.i(
        'Foreground FCM: title=${m.notification?.title} data=${m.data}',
      );
    });
    final token = await messaging.getToken();
    if (token != null) {
      await _registerTokenWithBackend(ref, token, 'fcm');
    }
    messaging.onTokenRefresh.listen((t) {
      unawaited(_registerTokenWithBackend(ref, t, 'fcm'));
    });
  }

  static Future<void> _initHms(WidgetRef ref) async {
    if (kIsWeb) {
      return;
    }
    await MobilePushProvider.requestPostNotificationPermissionIfNeeded();
    try {
      await hms.Push.setAutoInitEnabled(true);
    } catch (e, st) {
      logger.w('HMS setAutoInitEnabled: $e', stackTrace: st);
    }
    _started = true;
    unawaited(_hmsMessageSub?.cancel());
    _hmsMessageSub = hms.Push.onMessageReceivedStream.listen(
      (hms.RemoteMessage m) {
        logger.i('Foreground Huawei Push: data=${m.data}');
      },
      onError: (Object e) => logger.w('HMS onMessage: $e'),
    );
    unawaited(_hmsTokenSub?.cancel());
    _hmsTokenSub = hms.Push.getTokenStream.listen(
      (String t) {
        if (t.isNotEmpty) {
          unawaited(_registerTokenWithBackend(ref, t, 'hms'));
        }
      },
      onError: (Object e) => logger.w('Huawei getToken stream: $e'),
    );
    hms.Push.getToken(_hmsPushTokenScope);
  }

  static Future<void> _registerTokenWithBackend(
    WidgetRef ref,
    String token,
    String pushProvider,
  ) async {
    final url = RpcConfig.pushRegisterUrl.trim();
    if (url.isEmpty) {
      logger.i(
        'Push: set --dart-define=PUSH_REGISTER_URL=https://your.api/push/register to sync tokens',
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      logger.w('Push: invalid PUSH_REGISTER_URL');
      return;
    }
    String sol;
    try {
      final addrs = await ref
          .read(walletAddressesProvider.future)
          .timeout(const Duration(seconds: 12));
      sol = addrs.solana;
    } catch (_) {
      logger.w('Push: wallet addresses not ready; skip token registration');
      return;
    }
    if (sol.isEmpty) {
      logger.w('Push: empty Solana address; skip token registration');
      return;
    }
    try {
      final bearer = RpcConfig.pushRegisterBearer.trim();
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (bearer.isNotEmpty) 'Authorization': 'Bearer $bearer',
            },
            body: jsonEncode({
              'walletAddress': sol,
              'token': token,
              'platform': defaultTargetPlatform.name,
              'pushProvider': pushProvider,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        logger.i('Push token registered with backend ($pushProvider)');
      } else {
        logger.w('Push register HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e, st) {
      logger.e('Push register failed: $e', stackTrace: st);
    }
  }

  /// Demo / QA only — does not require [WidgetRef].
  static Future<void> debugInitializeDemo() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _debugFcm();
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final kind = await MobilePushProvider.getKind();
      if (kind == MobilePushProviderKind.hms) {
        await _debugHms();
        return;
      }
      if (kind == MobilePushProviderKind.fcm) {
        await _debugFcm();
        return;
      }
      logger.w('Push demo: no FCM or HMS');
    }
  }

  static Future<void> _debugFcm() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      logger.e('Demo Firebase init failed: $e');
      return;
    }
    await FirebaseMessaging.instance.requestPermission();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await MobilePushProvider.requestPostNotificationPermissionIfNeeded();
    }
    final token = await FirebaseMessaging.instance.getToken();
    logger.i('Demo FCM token: $token');
  }

  static Future<void> _debugHms() async {
    await MobilePushProvider.requestPostNotificationPermissionIfNeeded();
    await hms.Push.setAutoInitEnabled(true);
    final completer = Completer<String?>();
    final sub = hms.Push.getTokenStream.listen(
      (String t) {
        if (!completer.isCompleted && t.isNotEmpty) {
          completer.complete(t);
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
    );
    hms.Push.getToken(_hmsPushTokenScope);
    try {
      final t = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => null,
      );
      logger.i('Demo Huawei token: $t');
    } finally {
      await sub.cancel();
    }
  }
}
