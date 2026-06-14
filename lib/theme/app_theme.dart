import 'package:flutter/material.dart';
import 'tokens.dart';
import 'app_palette.dart';

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
      fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink);
  static const TextStyle h2 = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink);
  static const TextStyle h3 = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const TextStyle body = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const TextStyle caption = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mute);
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.mute,
    letterSpacing: 1.5,
  );
  static TextStyle jp(double size,
          {Color color = AppColors.ink, FontWeight w = FontWeight.w700}) =>
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
    return _base(
      brightness: Brightness.light,
      palette: AppPalette.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
    );
  }

  static ThemeData dark() {
    return _base(
      brightness: Brightness.dark,
      palette: AppPalette.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        surface: AppPalette.dark.surface,
      ),
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required AppPalette palette,
    required ColorScheme colorScheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.bg,
      canvasColor: palette.bg,
      cardColor: palette.surface,
      dividerColor: palette.line,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: palette.ink,
            displayColor: palette.ink,
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.input,
        hintStyle: TextStyle(color: palette.mute),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
