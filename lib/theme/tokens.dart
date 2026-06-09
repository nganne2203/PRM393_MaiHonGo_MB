import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFF8A7BFF);
  static const primaryDark = Color(0xFF5847D4);
  static const primarySoft = Color(0xFFEEEAFE);

  static const sakura = Color(0xFFFF8FB1);
  static const sakuraSoft = Color(0xFFFFE4ED);
  static const matcha = Color(0xFF7DCB8A);
  static const matchaSoft = Color(0xFFE3F5E6);
  static const sky = Color(0xFF7CC4F5);
  static const skySoft = Color(0xFFE3F1FB);
  static const gold = Color(0xFFFFC857);
  static const goldSoft = Color(0xFFFFF3D6);

  static const ink = Color(0xFF1F2138);
  static const mute = Color(0xFF8E90A6);
  static const line = Color(0xFFEDEDF4);
  static const bg = Color(0xFFFAFAFD);
  static const surface = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFF6F5FB);
}

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primary],
  );
  static const sakura = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB6C7), AppColors.sakura],
  );
  static const matcha = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA4DBA9), AppColors.matcha],
  );
  static const sky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB6DDF9), AppColors.sky],
  );
  static const warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD2A1), Color(0xFFFFA871)],
  );
  static const bgPage = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4F0FF), AppColors.bg, Color(0xFFFFF4F8)],
  );
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const pill = 999.0;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF1F2138).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -6,
    ),
  ];
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.4),
      blurRadius: 40,
      offset: const Offset(0, 15),
      spreadRadius: -15,
    ),
  ];
  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.5),
      blurRadius: 25,
      offset: const Offset(0, 10),
      spreadRadius: -5,
    ),
  ];
}
