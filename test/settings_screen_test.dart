import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snorer/core/theme/app_theme.dart';
import 'package:snorer/data/services/theme_preferences.dart';
import 'package:snorer/presentation/settings/settings_screen.dart';
import 'package:snorer/presentation/settings/theme_controller.dart';

void main() {
  testWidgets('selects and persists the Hurm theme', (tester) async {
    final preferences = _MemoryThemePreferences();
    final controller = ThemeController(preferences: preferences);
    await controller.initialize();

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          theme: buildSnorerTheme(controller.mode),
          home: SettingsScreen(themeController: controller),
        ),
      ),
    );

    expect(find.text('Donker'), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme_option_pink')));
    await tester.pumpAndSettle();

    expect(controller.mode, SnorerThemeMode.pink);
    expect(preferences.savedMode, SnorerThemeMode.pink);
    expect(
      Theme.of(
        tester.element(find.byType(SettingsScreen)),
      ).scaffoldBackgroundColor,
      buildSnorerTheme(SnorerThemeMode.pink).scaffoldBackgroundColor,
    );
  });

  test('restores the persisted light theme', () async {
    final preferences = _MemoryThemePreferences(initial: SnorerThemeMode.light);
    final controller = ThemeController(preferences: preferences);

    await controller.initialize();

    expect(controller.mode, SnorerThemeMode.light);
    expect(buildSnorerTheme(controller.mode).brightness, Brightness.light);
  });
}

class _MemoryThemePreferences implements ThemePreferences {
  _MemoryThemePreferences({SnorerThemeMode initial = SnorerThemeMode.dark})
    : _mode = initial;

  SnorerThemeMode _mode;
  SnorerThemeMode? savedMode;

  @override
  Future<SnorerThemeMode> load() async => _mode;

  @override
  Future<void> save(SnorerThemeMode mode) async {
    _mode = mode;
    savedMode = mode;
  }
}
