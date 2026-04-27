import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huawei_push/huawei_push.dart' as hms;

import 'app_navigator.dart';
import 'push/hms_background_entry.dart' show huaweiMessagingBackgroundMessageHandler;
import 'push/push_notification_service.dart' show firebaseMessagingBackgroundHandler;
import 'push/push_platform.dart' show MobilePushProvider, MobilePushProviderKind;
import 'providers/wallet_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/pin_auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stripe_paywall_screen.dart';
import 'screens/payment_thank_you_screen.dart';
import 'stripe/stripe_return_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (!kIsWeb) {
    await _registerBackgroundPushHandler();
  }
  runApp(
    const ProviderScope(
      child: VavelApp(),
    ),
  );
}

Future<void> _registerBackgroundPushHandler() async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    return;
  }
  if (defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  final kind = await MobilePushProvider.getKind();
  if (kind == MobilePushProviderKind.fcm) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } else if (kind == MobilePushProviderKind.hms) {
    await hms.Push.registerBackgroundMessageHandler(
      huaweiMessagingBackgroundMessageHandler,
    );
  }
}

class VavelApp extends ConsumerWidget {
  const VavelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('de'),
        Locale('da'),
        Locale('et'),
        Locale('pt'),
        Locale('uk'),
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2979FF),
          secondary: Color(0xFF2979FF),
          surface: Color(0xFF1A2A3E),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF2979FF),
          selectionColor: Color(0x552979FF),
          selectionHandleColor: Color(0xFF2979FF),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1B2E),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2979FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      home: const StripeReturnListener(
        child: _AppRouter(),
      ),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(appRouteProvider);
    // Do not use AnimatedSwitcher here: during the cross-fade the *outgoing*
    // route can stay above the incoming one in the hit-test stack, so taps
    // and TextFields on Home / Send / Support appear "dead" until animation ends.
    return KeyedSubtree(
      key: ValueKey<AppRoute>(route),
      child: switch (route) {
        AppRoute.setup => const SetupScreen(),
        AppRoute.pinAuth => const PinAuthScreen(),
        AppRoute.home => const HomeScreen(),
        AppRoute.paywall => const StripePaywallScreen(),
        AppRoute.paymentThanks => const PaymentThankYouScreen(),
      },
    );
  }
}
