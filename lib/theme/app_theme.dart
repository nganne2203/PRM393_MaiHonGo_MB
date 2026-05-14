import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTextStyles {
  static const TextStyle h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink);
  static const TextStyle h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink);
  static const TextStyle h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mute);
  static const TextStyle overline = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mute, letterSpacing: 1.5,
  );
  static TextStyle jp(double size, {Color color = AppColors.ink, FontWeight w = FontWeight.w700}) =>
      TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color,
        height: 1.0,
        fontFamilyFallback: const [
          'Hiragino Sans',
          'Noto Sans JP',
          'Noto Sans CJK JP',
          'Apple SD Gothic Neo',
        ],
      );
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
