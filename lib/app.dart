import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/snorer_localizations.dart';
import 'core/localization/snorer_language.dart';
import 'core/theme/app_theme.dart';
import 'presentation/recordings/recordings_screen.dart';
import 'presentation/recordings/recordings_view_model.dart';
import 'presentation/settings/language_controller.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/settings/theme_controller.dart';

class SnorerApp extends StatelessWidget {
  const SnorerApp({
    super.key,
    required this.viewModel,
    required this.themeController,
    required this.languageController,
  });

  final RecordingsViewModel viewModel;
  final ThemeController themeController;
  final LanguageController languageController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeController, languageController]),
      builder: (context, _) => MaterialApp(
        title: 'Snorer',
        debugShowCheckedModeBanner: false,
        locale: languageController.language.locale,
        supportedLocales: SnorerLocalizations.supportedLocales,
        localizationsDelegates: const [
          SnorerLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildSnorerTheme(themeController.mode),
        home: Builder(
          builder: (context) => RecordingsScreen(
            viewModel: viewModel,
            onOpenSettings: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(
                  themeController: themeController,
                  languageController: languageController,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
