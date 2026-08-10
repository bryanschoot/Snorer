import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/recording_repository.dart';
import 'data/services/app_update_service.dart';
import 'data/services/audio_playback_service.dart';
import 'data/services/audio_recording_service.dart';
import 'data/services/foreground_recording_service.dart';
import 'data/services/language_preferences.dart';
import 'data/services/recording_size_preferences.dart';
import 'data/services/sound_model_service.dart';
import 'data/services/theme_preferences.dart';
import 'presentation/recordings/recordings_view_model.dart';
import 'presentation/settings/language_controller.dart';
import 'presentation/settings/recording_size_controller.dart';
import 'presentation/settings/theme_controller.dart';
import 'presentation/update/update_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  final repository = LocalRecordingRepository();
  final foregroundController = AndroidForegroundRecordingController();
  final recorder = DeviceAudioRecordingService(
    repository: repository,
    soundModel: YamnetSoundModelService(),
    foregroundController: foregroundController,
  );
  final viewModel = RecordingsViewModel(
    repository: repository,
    recorder: recorder,
    player: JustAudioPlaybackService(),
  );
  final themeController = ThemeController(preferences: LocalThemePreferences());
  final languageController = LanguageController(
    preferences: LocalLanguagePreferences(),
  );
  final recordingSizeController = RecordingSizeController(
    preferences: LocalRecordingSizePreferences(),
  );
  await themeController.initialize();
  await languageController.initialize();
  await recordingSizeController.initialize();

  void syncNotificationTheme() {
    final palette = buildSnorerTheme(
      themeController.mode,
    ).extension<SnorerThemePalette>()!;
    foregroundController.setNotificationAccent(palette.primary);
  }

  syncNotificationTheme();
  themeController.addListener(syncNotificationTheme);
  foregroundController.setLanguage(languageController.language);
  languageController.addListener(() {
    foregroundController.setLanguage(languageController.language);
  });

  final packageInfo = await PackageInfo.fromPlatform();
  final updateController = UpdateController(
    currentVersion: packageInfo.version,
    service: GitHubAppUpdateService(),
  );

  runApp(
    SnorerApp(
      viewModel: viewModel,
      themeController: themeController,
      languageController: languageController,
      recordingSizeController: recordingSizeController,
      appVersion: packageInfo.version,
      appBuild: packageInfo.buildNumber,
      updateController: updateController,
    ),
  );
  unawaited(updateController.checkForUpdate());
}
