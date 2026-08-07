import 'package:flutter/foundation.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/theme_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({required this._preferences});

  final ThemePreferences _preferences;
  SnorerThemeMode _mode = SnorerThemeMode.dark;

  SnorerThemeMode get mode => _mode;

  Future<void> initialize() async {
    _mode = await _preferences.load();
    notifyListeners();
  }

  Future<void> setMode(SnorerThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _preferences.save(mode);
  }
}
