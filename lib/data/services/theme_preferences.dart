import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

abstract interface class ThemePreferences {
  Future<SnorerThemeMode> load();
  Future<void> save(SnorerThemeMode mode);
}

class LocalThemePreferences implements ThemePreferences {
  static const _storageKey = '@snorer/theme/v1';

  @override
  Future<SnorerThemeMode> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_storageKey);
    return switch (value) {
      'light' => SnorerThemeMode.light,
      'pink' => SnorerThemeMode.pink,
      _ => SnorerThemeMode.dark,
    };
  }

  @override
  Future<void> save(SnorerThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, mode.name);
  }
}
