import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_notification_service.dart';

class PushDemoScreen extends StatefulWidget {
  const PushDemoScreen({super.key});

  @override
  State<PushDemoScreen> createState() => _PushDemoScreenState();
}

class _PushDemoScreenState extends State<PushDemoScreen> {
  String? _token;
  String? _message;

  @override
  void initState() {
    super.initState();
    _initPush();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _message = message.notification?.title ?? 'Push: ${message.data}';
      });
    });
  }

  Future<void> _initPush() async {
    await PushNotificationService.debugInitializeDemo();
    _token = await FirebaseMessaging.instance.getToken();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('FCM Token:', style: Theme.of(context).textTheme.bodyLarge),
            SelectableText(_token ?? '...'),
            const SizedBox(height: 24),
            Text('Последнее уведомление:',
                style: Theme.of(context).textTheme.bodyLarge),
            Text(_message ?? 'Нет уведомлений'),
          ],
        ),
      ),
    );
  }
}
