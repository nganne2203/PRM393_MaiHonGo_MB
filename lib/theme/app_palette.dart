import 'package:flutter/material.dart';

import 'app_theme.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color input;
  final Color ink;
  final Color mute;
  final Color line;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.input,
    required this.ink,
    required this.mute,
    required this.line,
  });

  static const light = AppPalette(
    bg: Color(0xFFFAFAFD),
    surface: Color(0xFFFFFFFF),
    input: Color(0xFFF6F5FB),
    ink: Color(0xFF1F2138),
    mute: Color(0xFF8E90A6),
    line: Color(0xFFEDEDF4),
  );

  static const dark = AppPalette(
    bg: Color(0xFF12131F),
    surface: Color(0xFF1D1F32),
    input: Color(0xFF25283D),
    ink: Color(0xFFF4F4FA),
    mute: Color(0xFFA9ABC0),
    line: Color(0xFF32354D),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? input,
    Color? ink,
    Color? mute,
    Color? line,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      input: input ?? this.input,
      ink: ink ?? this.ink,
      mute: mute ?? this.mute,
      line: line ?? this.line,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      input: Color.lerp(input, other.input, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  TextStyle get h1 => AppTextStyles.h1.copyWith(color: colors.ink);
  TextStyle get h2 => AppTextStyles.h2.copyWith(color: colors.ink);
  TextStyle get h3 => AppTextStyles.h3.copyWith(color: colors.ink);
  TextStyle get bodyText => AppTextStyles.body.copyWith(color: colors.ink);
  TextStyle get captionText =>
      AppTextStyles.caption.copyWith(color: colors.mute);
  TextStyle get overlineText =>
      AppTextStyles.overline.copyWith(color: colors.mute);
}
