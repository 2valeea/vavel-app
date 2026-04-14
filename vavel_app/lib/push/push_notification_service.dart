import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../firebase_options.dart';
import '../providers/wallet_provider.dart';
import '../utils/logger.dart';

/// Must be registered in [main] before [runApp] (see `lib/main.dart`).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  logger.i('Background FCM: id=${message.messageId} data=${message.data}');
}

const _kNotifyTx = 'notify_tx';

class PushNotificationService {
  static bool _started = false;

  /// Called from [HomeScreen] after unlock when transaction alerts are enabled.
  static Future<void> maybeInitializeAfterUnlock(WidgetRef ref) async {
    if (_started) return;
    if (kIsWeb) return;

    const storage = FlutterSecureStorage();
    final notifyRaw = await storage.read(key: _kNotifyTx);
    final notifyTx = notifyRaw != 'false';
    if (!notifyTx) {
      logger.i('FCM: transaction alerts disabled; skip Firebase init');
      return;
    }

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

    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      logger.i(
        'Foreground FCM: title=${m.notification?.title} data=${m.data}',
      );
    });

    final token = await messaging.getToken();
    if (token != null) {
      await _registerTokenWithBackend(ref, token);
    }

    messaging.onTokenRefresh.listen((t) {
      unawaited(_registerTokenWithBackend(ref, t));
    });
  }

  static Future<void> _registerTokenWithBackend(
    WidgetRef ref,
    String token,
  ) async {
    final url = RpcConfig.pushRegisterUrl.trim();
    if (url.isEmpty) {
      logger.i(
        'FCM: set --dart-define=PUSH_REGISTER_URL=https://your.api/push/register to sync tokens',
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      logger.w('FCM: invalid PUSH_REGISTER_URL');
      return;
    }

    String eth;
    try {
      final addrs = await ref
          .read(walletAddressesProvider.future)
          .timeout(const Duration(seconds: 12));
      eth = addrs.ethereum;
    } catch (_) {
      logger.w('FCM: wallet addresses not ready; skip token registration');
      return;
    }
    if (eth.isEmpty) {
      logger.w('FCM: empty Ethereum address; skip token registration');
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
              'walletAddress': eth,
              'token': token,
              'platform': defaultTargetPlatform.name,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        logger.i('FCM token registered with backend');
      } else {
        logger.w('FCM register HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e, st) {
      logger.e('FCM register failed: $e', stackTrace: st);
    }
  }

  /// Demo / QA only — does not require [WidgetRef].
  static Future<void> debugInitializeDemo() async {
    if (kIsWeb) return;
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
    final token = await FirebaseMessaging.instance.getToken();
    logger.i('Demo FCM token: $token');
  }
}
