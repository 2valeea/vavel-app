import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logger.dart';

import 'package:http/http.dart' as http;

class PushNotificationService {
  static Future<void> initialize(
      {required String walletAddress, required String jwtToken}) async {
    await Firebase.initializeApp();
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Запрос разрешения на уведомления (iOS)
    await messaging.requestPermission();

    // Получение токена устройства
    String? token = await messaging.getToken();
    logger.i('FCM Token: $token');

    // Отправка токена на backend с авторизацией и адресом кошелька
    if (token != null) {
      await sendTokenToBackend(token, walletAddress, jwtToken);
    }

    // Обработка входящих уведомлений в фоновом режиме
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> sendTokenToBackend(
      String token, String walletAddress, String jwtToken) async {
    final response = await http.post(
      Uri.parse('https://your-backend.com/api/push/register'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
      body: {'walletAddress': walletAddress, 'token': token},
    );
    if (response.statusCode == 200) {
      logger.i('Token registered on backend');
    } else {
      logger.e('Failed to register token: ${response.body}');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    logger.i('Обработано фоновое уведомление: ${message.messageId}');
  }
}
