import 'package:flutter/material.dart';

enum SnorerLanguage { dutch, english }

extension SnorerLanguageDetails on SnorerLanguage {
  Locale get locale => switch (this) {
    SnorerLanguage.dutch => const Locale('nl'),
    SnorerLanguage.english => const Locale('en'),
  };

  String get storageValue => locale.languageCode;
}

SnorerLanguage snorerLanguageFromStorageValue(String? value) => switch (value) {
  'en' => SnorerLanguage.english,
  _ => SnorerLanguage.dutch,
};
