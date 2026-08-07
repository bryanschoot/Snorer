import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/snorer_language.dart';

abstract interface class LanguagePreferences {
  Future<SnorerLanguage> load();
  Future<void> save(SnorerLanguage language);
}

class LocalLanguagePreferences implements LanguagePreferences {
  static const _storageKey = '@snorer/language/v1';

  @override
  Future<SnorerLanguage> load() async {
    final preferences = await SharedPreferences.getInstance();
    return snorerLanguageFromStorageValue(preferences.getString(_storageKey));
  }

  @override
  Future<void> save(SnorerLanguage language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, language.storageValue);
  }
}
