import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _deepPurple = Color(0xFF1A1028);
  static const _darkSurface = Color(0xFF0D0A14);
  static const _gold = Color(0xFFD4A84B);
  static const _softPurple = Color(0xFF6B5B95);
  static const _textPrimary = Color(0xFFE8E0F0);
  static const _textSecondary = Color(0xFF9B8FB8);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkSurface,
        colorScheme: const ColorScheme.dark(
          primary: _gold,
          secondary: _softPurple,
          surface: _deepPurple,
          onPrimary: _darkSurface,
          onSecondary: _textPrimary,
          onSurface: _textPrimary,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: _textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkSurface,
          foregroundColor: _textPrimary,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: _deepPurple,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
}
