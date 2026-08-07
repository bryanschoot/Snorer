import 'package:flutter/material.dart';

enum SnorerThemeMode { dark, light, pink }

extension SnorerThemeModeDetails on SnorerThemeMode {
  String get label => switch (this) {
    SnorerThemeMode.dark => 'Donker',
    SnorerThemeMode.light => 'Licht',
    SnorerThemeMode.pink => 'Roze',
  };

  String get description => switch (this) {
    SnorerThemeMode.dark => 'Rustig voor de nacht',
    SnorerThemeMode.light => 'Helder overdag',
    SnorerThemeMode.pink => 'Warm en zacht',
  };

  IconData get icon => switch (this) {
    SnorerThemeMode.dark => Icons.dark_mode_outlined,
    SnorerThemeMode.light => Icons.light_mode_outlined,
    SnorerThemeMode.pink => Icons.favorite_border_rounded,
  };
}

@immutable
class SnorerThemePalette extends ThemeExtension<SnorerThemePalette> {
  const SnorerThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSoft,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.secondary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.danger,
    required this.dangerDark,
    required this.warning,
    required this.warningBackground,
    required this.warningBorder,
    required this.warningText,
    required this.errorBackground,
    required this.errorBorder,
    required this.errorText,
    required this.waveInactive,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSoft;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color secondary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color danger;
  final Color dangerDark;
  final Color warning;
  final Color warningBackground;
  final Color warningBorder;
  final Color warningText;
  final Color errorBackground;
  final Color errorBorder;
  final Color errorText;
  final Color waveInactive;

  @override
  SnorerThemePalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSoft,
    Color? border,
    Color? text,
    Color? muted,
    Color? primary,
    Color? primaryDark,
    Color? onPrimary,
    Color? secondary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? danger,
    Color? dangerDark,
    Color? warning,
    Color? warningBackground,
    Color? warningBorder,
    Color? warningText,
    Color? errorBackground,
    Color? errorBorder,
    Color? errorText,
    Color? waveInactive,
  }) {
    return SnorerThemePalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      danger: danger ?? this.danger,
      dangerDark: dangerDark ?? this.dangerDark,
      warning: warning ?? this.warning,
      warningBackground: warningBackground ?? this.warningBackground,
      warningBorder: warningBorder ?? this.warningBorder,
      warningText: warningText ?? this.warningText,
      errorBackground: errorBackground ?? this.errorBackground,
      errorBorder: errorBorder ?? this.errorBorder,
      errorText: errorText ?? this.errorText,
      waveInactive: waveInactive ?? this.waveInactive,
    );
  }

  @override
  SnorerThemePalette lerp(
    covariant ThemeExtension<SnorerThemePalette>? other,
    double t,
  ) {
    if (other is! SnorerThemePalette) return this;
    return SnorerThemePalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerDark: Color.lerp(dangerDark, other.dangerDark, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      waveInactive: Color.lerp(waveInactive, other.waveInactive, t)!,
    );
  }
}

extension SnorerThemeContext on BuildContext {
  SnorerThemePalette get snorerColors =>
      Theme.of(this).extension<SnorerThemePalette>()!;
}

ThemeData buildSnorerTheme([SnorerThemeMode mode = SnorerThemeMode.dark]) {
  final palette = switch (mode) {
    SnorerThemeMode.dark => const SnorerThemePalette(
      background: Color(0xFF071A2D),
      surface: Color(0xFF102A43),
      surfaceRaised: Color(0xFF163B5C),
      surfaceSoft: Color(0xFF12314C),
      border: Color(0xFF285474),
      text: Color(0xFFF3F8FC),
      muted: Color(0xFFA8C0D4),
      primary: Color(0xFF5ED0C0),
      primaryDark: Color(0xFF2B9C91),
      onPrimary: Color(0xFF071A2D),
      secondary: Color(0xFF9CB0FF),
      primaryContainer: Color(0xFF174C4A),
      onPrimaryContainer: Color(0xFFB3F4E9),
      danger: Color(0xFFFF8B8B),
      dangerDark: Color(0xFF9D3F55),
      warning: Color(0xFFFFD166),
      warningBackground: Color(0xFF382F2A),
      warningBorder: Color(0xFF765A35),
      warningText: Color(0xFFE8D9BD),
      errorBackground: Color(0xFF3A2938),
      errorBorder: Color(0xFF744251),
      errorText: Color(0xFFF1D9DE),
      waveInactive: Color(0xFF4D7490),
    ),
    SnorerThemeMode.light => const SnorerThemePalette(
      background: Color(0xFFF5F8FA),
      surface: Color(0xFFFFFFFF),
      surfaceRaised: Color(0xFFFFFFFF),
      surfaceSoft: Color(0xFFEAF3F4),
      border: Color(0xFFD5E1E5),
      text: Color(0xFF102A3A),
      muted: Color(0xFF5D7180),
      primary: Color(0xFF0A8F86),
      primaryDark: Color(0xFF08736D),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF5967A8),
      primaryContainer: Color(0xFFC7EFEB),
      onPrimaryContainer: Color(0xFF073D3A),
      danger: Color(0xFFC43D55),
      dangerDark: Color(0xFF9A2940),
      warning: Color(0xFF9A6200),
      warningBackground: Color(0xFFFFF5D8),
      warningBorder: Color(0xFFE9CF82),
      warningText: Color(0xFF654400),
      errorBackground: Color(0xFFFFE8EC),
      errorBorder: Color(0xFFF0B7C1),
      errorText: Color(0xFF7C1F31),
      waveInactive: Color(0xFF9AB2BB),
    ),
    SnorerThemeMode.pink => const SnorerThemePalette(
      background: Color(0xFFFFF4F8),
      surface: Color(0xFFFFFFFF),
      surfaceRaised: Color(0xFFFFFAFC),
      surfaceSoft: Color(0xFFFFE7F0),
      border: Color(0xFFF1B9CD),
      text: Color(0xFF3A1F2A),
      muted: Color(0xFF8B5D70),
      primary: Color(0xFFD44987),
      primaryDark: Color(0xFFA92E68),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF8054A6),
      primaryContainer: Color(0xFFFFD3E3),
      onPrimaryContainer: Color(0xFF5D1236),
      danger: Color(0xFFC13B5C),
      dangerDark: Color(0xFF982946),
      warning: Color(0xFF9A6200),
      warningBackground: Color(0xFFFFF0D1),
      warningBorder: Color(0xFFE8C57A),
      warningText: Color(0xFF634300),
      errorBackground: Color(0xFFFFE7EE),
      errorBorder: Color(0xFFF0B3C4),
      errorText: Color(0xFF7E1D38),
      waveInactive: Color(0xFFD69BB2),
    ),
  };

  final brightness = mode == SnorerThemeMode.dark
      ? Brightness.dark
      : Brightness.light;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
        surface: palette.surface,
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        secondary: palette.secondary,
        onSurface: palette.text,
        error: palette.danger,
      ).copyWith(
        outline: palette.border,
        onSurfaceVariant: palette.muted,
        primaryContainer: palette.primaryContainer,
        onPrimaryContainer: palette.onPrimaryContainer,
        surfaceContainerHighest: palette.surfaceRaised,
      );
  final baseText = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    textTheme: baseText.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
      fontFamily: 'sans',
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.text,
      elevation: 0,
      titleTextStyle: baseText.titleLarge?.copyWith(
        color: palette.text,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(color: palette.border),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceRaised,
      contentTextStyle: TextStyle(color: palette.text),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.primary,
      textColor: palette.text,
      subtitleTextStyle: TextStyle(color: palette.muted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    extensions: <ThemeExtension<dynamic>>[palette],
  );
}
