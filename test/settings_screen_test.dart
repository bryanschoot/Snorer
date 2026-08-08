import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snorer/core/localization/snorer_language.dart';
import 'package:snorer/core/localization/snorer_localizations.dart';
import 'package:snorer/core/theme/app_theme.dart';
import 'package:snorer/data/services/language_preferences.dart';
import 'package:snorer/data/services/app_update_service.dart';
import 'package:snorer/data/services/theme_preferences.dart';
import 'package:snorer/presentation/settings/language_controller.dart';
import 'package:snorer/presentation/settings/settings_screen.dart';
import 'package:snorer/presentation/update/update_controller.dart';
import 'package:snorer/presentation/settings/theme_controller.dart';

void main() {
  testWidgets('selects and persists the Hurm theme', (tester) async {
    final preferences = _MemoryThemePreferences();
    final controller = ThemeController(preferences: preferences);
    final languageController = LanguageController(
      preferences: _MemoryLanguagePreferences(),
    );
    await controller.initialize();
    await languageController.initialize();
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          theme: buildSnorerTheme(controller.mode),
          home: SettingsScreen(
            themeController: controller,
            languageController: languageController,
          ),
        ),
      ),
    );

    expect(find.text('Donker'), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme_option_pink')));
    await tester.pumpAndSettle();

    expect(controller.mode, SnorerThemeMode.pink);
    expect(find.byKey(const Key('theme_selected_pink')), findsOneWidget);
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
  testWidgets('switches and persists the English language', (tester) async {
    final languagePreferences = _MemoryLanguagePreferences();
    final languageController = LanguageController(
      preferences: languagePreferences,
    );
    final themeController = ThemeController(
      preferences: _MemoryThemePreferences(),
    );
    await languageController.initialize();
    await themeController.initialize();

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: Listenable.merge([themeController, languageController]),
        builder: (context, _) => MaterialApp(
          locale: languageController.language.locale,
          supportedLocales: SnorerLocalizations.supportedLocales,
          localizationsDelegates: const [
            SnorerLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildSnorerTheme(themeController.mode),
          home: SettingsScreen(
            themeController: themeController,
            languageController: languageController,
          ),
        ),
      ),
    );

    expect(find.text('Instellingen'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language_option_english')));
    await tester.pumpAndSettle();

    expect(languageController.language, SnorerLanguage.english);
    expect(languagePreferences.savedLanguage, SnorerLanguage.english);
    expect(find.text('Settings'), findsOneWidget);
  });

  test('serializes rapid theme changes and keeps the latest choice', () async {
    final preferences = _SlowThemePreferences();
    final controller = ThemeController(preferences: preferences);
    await controller.initialize();

    final firstSave = controller.setMode(SnorerThemeMode.light);
    final secondSave = controller.setMode(SnorerThemeMode.pink);

    await Future<void>.delayed(Duration.zero);
    expect(preferences.savedModes, [SnorerThemeMode.light]);
    preferences.gates.first.complete();
    await firstSave;
    await Future<void>.delayed(Duration.zero);
    expect(preferences.savedModes, [
      SnorerThemeMode.light,
      SnorerThemeMode.pink,
    ]);
    preferences.gates.last.complete();
    await secondSave;
    expect(controller.mode, SnorerThemeMode.pink);
  });
  testWidgets('checks for updates and starts direct installation', (
    tester,
  ) async {
    final service = _FakeUpdateService(
      AppRelease(
        tagName: 'v0.2.5',
        version: const AppVersion(0, 2, 5),
        releaseUrl: Uri.parse(
          'https://github.com/bryanschoot/Snorer/releases/tag/v0.2.5',
        ),
        apkUrl: Uri.parse(
          'https://github.com/bryanschoot/Snorer/releases/download/v0.2.5/snorer-v0.2.5.apk',
        ),
        checksumUrl: Uri.parse(
          'https://github.com/bryanschoot/Snorer/releases/download/v0.2.5/snorer-v0.2.5.apk.sha256',
        ),
      ),
    );
    final updateController = UpdateController(
      currentVersion: '0.2.4',
      service: service,
    );
    final themeController = ThemeController(
      preferences: _MemoryThemePreferences(),
    );
    final languageController = LanguageController(
      preferences: _MemoryLanguagePreferences(),
    );
    await themeController.initialize();
    await languageController.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: SettingsScreen(
          themeController: themeController,
          languageController: languageController,
          updateController: updateController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.byKey(const Key('check_for_updates')),
      500,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const Key('check_for_updates')));
    await tester.pumpAndSettle();

    expect(service.checks, 1);
    expect(
      updateController.status,
      UpdateCheckStatus.updateAvailable,
    );
    expect(find.byKey(const Key('install_update')), findsOneWidget);
    expect(find.byKey(const Key('open_update_release')), findsOneWidget);

    await tester.tap(find.byKey(const Key('install_update')));
    await tester.pumpAndSettle();

    expect(service.installs, 1);
    expect(updateController.status, UpdateCheckStatus.installStarted);
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
class _SlowThemePreferences implements ThemePreferences {
  final savedModes = <SnorerThemeMode>[];
  final gates = <Completer<void>>[];

  @override
  Future<SnorerThemeMode> load() async => SnorerThemeMode.dark;

  @override
  Future<void> save(SnorerThemeMode mode) async {
    savedModes.add(mode);
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
  }
}

class _MemoryLanguagePreferences implements LanguagePreferences {
  _MemoryLanguagePreferences({SnorerLanguage initial = SnorerLanguage.dutch})
    : _language = initial;

  SnorerLanguage _language;
  SnorerLanguage? savedLanguage;

  @override
  Future<SnorerLanguage> load() async => _language;

  @override
  Future<void> save(SnorerLanguage language) async {
    _language = language;
    savedLanguage = language;
  }
}

class _FakeUpdateService implements AppUpdateService {
  _FakeUpdateService(this.release);

  final AppRelease? release;
  int checks = 0;
  int installs = 0;

  @override
  Future<AppRelease?> checkForUpdate(String currentVersion) async {
    checks += 1;
    return release;
  }
  @override
  Future<ApkInstallResult> install(AppRelease release) async {
    installs += 1;
    return ApkInstallResult.started;
  }

  @override
  void dispose() {}
}
