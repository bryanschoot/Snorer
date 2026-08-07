import 'package:flutter/material.dart';

abstract final class SnorerColors {
  static const background = Color(0xFF071A2D);
  static const surface = Color(0xFF102A43);
  static const surfaceRaised = Color(0xFF163B5C);
  static const surfaceSoft = Color(0xFF12314C);
  static const border = Color(0xFF285474);
  static const text = Color(0xFFF3F8FC);
  static const muted = Color(0xFFA8C0D4);
  static const primary = Color(0xFF5ED0C0);
  static const primaryDark = Color(0xFF2B9C91);
  static const danger = Color(0xFFFF8B8B);
  static const dangerDark = Color(0xFF9D3F55);
  static const warning = Color(0xFFFFD166);
  static const warningBackground = Color(0xFF382F2A);
  static const warningBorder = Color(0xFF765A35);
  static const warningText = Color(0xFFE8D9BD);
  static const errorBackground = Color(0xFF3A2938);
  static const errorBorder = Color(0xFF744251);
  static const errorText = Color(0xFFF1D9DE);
  static const waveInactive = Color(0xFF4D7490);
}

ThemeData buildSnorerTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SnorerColors.primary,
    brightness: Brightness.dark,
    surface: SnorerColors.surface,
    primary: SnorerColors.primary,
    onPrimary: SnorerColors.background,
    secondary: const Color(0xFF9CB0FF),
    onSurface: SnorerColors.text,
  );
  final baseText = ThemeData.dark().textTheme;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SnorerColors.background,
    textTheme: baseText.apply(
      bodyColor: SnorerColors.text,
      displayColor: SnorerColors.text,
      fontFamily: 'sans',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: SnorerColors.text,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: SnorerColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: SnorerColors.border),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: SnorerColors.surfaceRaised,
      contentTextStyle: TextStyle(color: SnorerColors.text),
    ),
  );
}
