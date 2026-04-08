import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/wallet_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/pin_auth_screen.dart';
import 'screens/home_screen.dart';

void main() => runApp(const ProviderScope(child: VavelApp()));

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
    return switch (route) {
      AppRoute.setup => const SetupScreen(),
      AppRoute.pinAuth => const PinAuthScreen(),
      AppRoute.home => const HomeScreen(),
    };
  }
}
