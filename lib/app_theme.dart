import 'package:flutter/material.dart';

/// Cogniaware risk levels for color coding (green / yellow / orange).
enum CogniawareRiskLevel { stable, moderate, increased }

/// Modern calm theme: blue header, soft neutrals, green/blue accents.
class CogniawareTheme {
  static CogniawareTheme of(BuildContext context) {
    return CogniawareTheme();
  }

  static CogniawareRiskLevel riskLevelForIndex(double index) {
    if (index >= 70) return CogniawareRiskLevel.stable;
    if (index >= 45) return CogniawareRiskLevel.moderate;
    return CogniawareRiskLevel.increased;
  }

  // Header & primary actions
  static const Color headerBlue = Color(0xFF2563EB);
  static const Color headerBlueDark = Color(0xFF1D4ED8);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Surfaces
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardGray = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);

  // Risk colors: green = stable, yellow = moderate, orange = increased
  static const Color riskStable = Color(0xFF22C55E);
  static const Color riskModerate = Color(0xFFEAB308);
  static const Color riskIncreased = Color(0xFFF97316);

  // Progress / accent
  static const Color progressBlue = Color(0xFF3B82F6);
  static const Color progressPurple = Color(0xFF8B5CF6);

  Color riskColor(CogniawareRiskLevel level) {
    switch (level) {
      case CogniawareRiskLevel.stable:
        return riskStable;
      case CogniawareRiskLevel.moderate:
        return riskModerate;
      case CogniawareRiskLevel.increased:
        return riskIncreased;
    }
  }

  TextStyle? get headlineIndex => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  TextStyle? get headline => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  TextStyle? get subtitle1 => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  TextStyle? get body => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  TextStyle? get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );
}

/// App-wide ThemeData for MaterialApp.
ThemeData getCogniawareMaterialTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: CogniawareTheme.primary,
      surface: CogniawareTheme.surface,
      onPrimary: Colors.white,
      onSurface: CogniawareTheme.textPrimary,
      outline: CogniawareTheme.divider,
    ),
    scaffoldBackgroundColor: CogniawareTheme.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: CogniawareTheme.headerBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: CogniawareTheme.surfaceLight,
      elevation: 0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CogniawareTheme.divider, width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: CogniawareTheme.surfaceLight,
      selectedItemColor: CogniawareTheme.primary,
      unselectedItemColor: CogniawareTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
