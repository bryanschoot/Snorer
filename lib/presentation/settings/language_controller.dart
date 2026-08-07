import 'package:flutter/foundation.dart';

import '../../core/localization/snorer_language.dart';
import '../../data/services/language_preferences.dart';

class LanguageController extends ChangeNotifier {
  LanguageController({required this._preferences});

  final LanguagePreferences _preferences;
  SnorerLanguage _language = SnorerLanguage.dutch;

  SnorerLanguage get language => _language;

  Future<void> initialize() async {
    _language = await _preferences.load();
    notifyListeners();
  }

  Future<void> setLanguage(SnorerLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await _preferences.save(language);
  }
}
