import 'package:flutter/material.dart';

class EmeraldNFTGalleryTheme {
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF50fa7b),
        scaffoldBackgroundColor: const Color(0xFF222b22),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1a221a),
          foregroundColor: Color(0xFF50fa7b),
          elevation: 0,
        ),
        cardColor: const Color(0xFF263326),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF50fa7b),
          secondary: Color(0xFF1de9b6),
          surface: Color(0xFF222b22),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color(0xFF50fa7b)),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF50fa7b),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
