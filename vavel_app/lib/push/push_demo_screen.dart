import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:huawei_push/huawei_push.dart' as hms;

import 'push_notification_service.dart';
import 'push_platform.dart' show MobilePushProvider, MobilePushProviderKind;

class PushDemoScreen extends StatefulWidget {
  const PushDemoScreen({super.key});

  @override
  State<PushDemoScreen> createState() => _PushDemoScreenState();
}

class _PushDemoScreenState extends State<PushDemoScreen> {
  String? _token;
  String? _message;
  String _provider = '…';

  @override
  void initState() {
    super.initState();
    unawaited(_initPush());
  }

  Future<void> _initPush() async {
    final kind = await MobilePushProvider.getKind();
    setState(() {
      _provider = switch (kind) {
        MobilePushProviderKind.hms => 'HMS (Huawei Push Kit)',
        MobilePushProviderKind.fcm => 'FCM (Google / Firebase)',
        _ => 'none',
      };
    });
    if (kind == MobilePushProviderKind.hms) {
      await PushNotificationService.debugInitializeDemo();
      hms.Push.onMessageReceivedStream.listen(
        (hms.RemoteMessage m) {
          if (mounted) {
            setState(() {
              _message = 'HMS: ${m.data}';
            });
          }
        },
      );
      final t = await _hmsTokenOnce();
      if (mounted) {
        setState(() => _token = t);
      }
      return;
    }
    if (kind == MobilePushProviderKind.fcm) {
      await PushNotificationService.debugInitializeDemo();
      if (!mounted) {
        return;
      }
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        setState(() {
          _message = message.notification?.title ?? 'Push: ${message.data}';
        });
      });
      _token = await FirebaseMessaging.instance.getToken();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<String?> _hmsTokenOnce() async {
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
    hms.Push.getToken('');
    try {
      return await completer.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => null,
      );
    } finally {
      await sub.cancel();
    }
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
            Text('Provider: $_provider',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Token', style: Theme.of(context).textTheme.bodyLarge),
            SelectableText(_token ?? '...'),
            const SizedBox(height: 24),
            Text('Last message / notification:',
                style: Theme.of(context).textTheme.bodyLarge),
            Text(_message ?? 'None'),
          ],
        ),
      ),
    );
  }
}
