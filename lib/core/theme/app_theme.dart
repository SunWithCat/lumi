import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 浪漫粉白色调
  // static const _primaryPink = Color(0xFFFF85A2);
  // static const _lightPink = Color(0xFFFFB6C8);
  // static const _softPink = Color(0xFFFFF0F3);
  // static const _deepPink = Color(0xFFE91E63);
  // static const _lavender = Color(0xFFE8D5E7);

  static ThemeData get romantic => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFFFF85A2),
      secondary: const Color(0xFFFFB6C8),
      surface: Colors.white,
      background: const Color(0xFFFFF5F7),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: const Color(0xFF333333),
      onBackground: const Color(0xFF333333),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF5F7),
    extensions: const [LumiColors.romantic],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFFF85A2)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0xFFFF85A2).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );

  // 保留暗色主题备用
  // static ThemeData get dark => ThemeData(
  //   useMaterial3: true,
  //   brightness: Brightness.dark,
  //   colorScheme: const ColorScheme.dark(
  //     primary: _primaryPink,
  //     secondary: _lavender,
  //     surface: Color(0xFF2A2A3E),
  //     error: Color(0xFFCF6679),
  //   ),
  //   scaffoldBackgroundColor: const Color(0xFF1A1A2E),
  // );

  // 蓝白主题
  static ThemeData get ocean => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF64B5F6),
      secondary: const Color(0xFF90CAF9),
      surface: Colors.white,
      background: const Color(0xFFF5F9FF),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: const Color(0xFF333333),
      onBackground: const Color(0xFF333333),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F9FF),
    extensions: const [LumiColors.ocean],
    // ... 其他配置
  );
}

class LumiColors extends ThemeExtension<LumiColors> {
  final Color primaryGradientStart;
  final Color primaryGradientEnd;
  final Color backgroundGradientTop;
  final Color backgroundGradientMiddle;
  final Color messageBubbleAI;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color shadowColor;

  const LumiColors({
    required this.primaryGradientStart,
    required this.primaryGradientEnd,
    required this.backgroundGradientTop,
    required this.backgroundGradientMiddle,
    required this.messageBubbleAI,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.shadowColor,
  });

  // 粉白主题颜色
  static const romantic = LumiColors(
    primaryGradientStart: Color(0xFFFF85A2),
    primaryGradientEnd: Color(0xFFFF6B8A),
    backgroundGradientTop: Color(0xFFFFE4EC),
    backgroundGradientMiddle: Color(0xFFFFF5F7),
    messageBubbleAI: Color(0xFFFFE4EC),
    textPrimary: Color(0xFF333333),
    textSecondary: Color(0xFF666666),
    textTertiary: Color(0xFF4A4A4A),
    shadowColor: Color(0xFFFF85A2),
  );

  // 蓝白主题颜色
  static const ocean = LumiColors(
    primaryGradientStart: Color(0xFF64B5F6),
    primaryGradientEnd: Color(0xFF42A5F5),
    backgroundGradientTop: Color(0xFFE3F2FD),
    backgroundGradientMiddle: Color(0xFFF5F9FF),
    messageBubbleAI: Color(0xFFE3F2FD),
    textPrimary: Color(0xFF333333),
    textSecondary: Color(0xFF666666),
    textTertiary: Color(0xFF4A4A4A),
    shadowColor: Color(0xFF64B5F6),
  );

  @override
  LumiColors copyWith({
    Color? primaryGradientStart,
    Color? primaryGradientEnd,
    Color? backgroundGradientTop,
    Color? backgroundGradientMiddle,
    Color? messageBubbleAI,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? shadowColor,
  }) {
    return LumiColors(
      primaryGradientStart: primaryGradientStart ?? this.primaryGradientStart,
      primaryGradientEnd: primaryGradientEnd ?? this.primaryGradientEnd,
      backgroundGradientTop:
          backgroundGradientTop ?? this.backgroundGradientTop,
      backgroundGradientMiddle:
          backgroundGradientMiddle ?? this.backgroundGradientMiddle,
      messageBubbleAI: messageBubbleAI ?? this.messageBubbleAI,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  LumiColors lerp(LumiColors? other, double t) {
    if (other is! LumiColors) {
      return this;
    }
    return LumiColors(
      primaryGradientStart: Color.lerp(
        primaryGradientStart,
        other.primaryGradientStart,
        t,
      )!,
      primaryGradientEnd: Color.lerp(
        primaryGradientEnd,
        other.primaryGradientEnd,
        t,
      )!,
      backgroundGradientTop: Color.lerp(
        backgroundGradientTop,
        other.backgroundGradientTop,
        t,
      )!,
      backgroundGradientMiddle: Color.lerp(
        backgroundGradientMiddle,
        other.backgroundGradientMiddle,
        t,
      )!,
      messageBubbleAI: Color.lerp(messageBubbleAI, other.messageBubbleAI, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

extension LumiColorsExtension on BuildContext {
  LumiColors get lumiColors => Theme.of(this).extension<LumiColors>()!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
