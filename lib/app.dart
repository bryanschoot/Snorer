import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/recordings/recordings_screen.dart';
import 'presentation/recordings/recordings_view_model.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/settings/theme_controller.dart';

class SnorerApp extends StatelessWidget {
  const SnorerApp({
    super.key,
    required this.viewModel,
    required this.themeController,
  });

  final RecordingsViewModel viewModel;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => MaterialApp(
        title: 'Snorer',
        debugShowCheckedModeBanner: false,
        theme: buildSnorerTheme(themeController.mode),
        home: RecordingsScreen(
          viewModel: viewModel,
          onOpenSettings: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(themeController: themeController),
            ),
          ),
        ),
      ),
    );
  }
}
