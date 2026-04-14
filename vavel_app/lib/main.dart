import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push/push_notification_service.dart';
import 'providers/wallet_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/pin_auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dapp_connect_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // FCM background isolate is mobile-only; registering on web is unsupported noise.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const ProviderScope(child: VavelApp()));
}

class VavelApp extends ConsumerWidget {
  const VavelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
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
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(appRouteProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.988, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<AppRoute>(route),
        child: switch (route) {
          AppRoute.setup => const SetupScreen(),
          AppRoute.pinAuth => const PinAuthScreen(),
          AppRoute.home => const HomeScreen(),
          AppRoute.dappConnect => const DappConnectScreen(),
        },
      ),
    );
  }
}
