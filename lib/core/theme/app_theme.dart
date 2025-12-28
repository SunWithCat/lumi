import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 浪漫粉白色调
  static const _primaryPink = Color(0xFFFF85A2);
  // static const _lightPink = Color(0xFFFFB6C8);
  static const _softPink = Color(0xFFFFF0F3);
  // static const _deepPink = Color(0xFFE91E63);
  static const _lavender = Color(0xFFE8D5E7);

  static ThemeData get romantic => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryPink,
      secondary: _lavender,
      surface: Colors.white,
      surfaceContainerHighest: _softPink,
      error: const Color(0xFFE57373),
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: _softPink,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: _primaryPink),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: _primaryPink.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
    ),
  );

  // 保留暗色主题备用
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryPink,
      secondary: _lavender,
      surface: Color(0xFF2A2A3E),
      error: Color(0xFFCF6679),
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
  );
}
