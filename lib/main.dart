import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app.dart';
import 'data/repositories/recording_repository.dart';
import 'data/services/audio_playback_service.dart';
import 'data/services/audio_recording_service.dart';
import 'data/services/foreground_recording_service.dart';
import 'data/services/sound_model_service.dart';
import 'presentation/recordings/recordings_view_model.dart';
import 'data/services/theme_preferences.dart';
import 'presentation/settings/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  final repository = LocalRecordingRepository();
  final recorder = DeviceAudioRecordingService(
    repository: repository,
    soundModel: YamnetSoundModelService(),
    foregroundController: AndroidForegroundRecordingController(),
  );
  final viewModel = RecordingsViewModel(
    repository: repository,
    recorder: recorder,
    player: JustAudioPlaybackService(),
  );
  final themeController = ThemeController(preferences: LocalThemePreferences());
  await themeController.initialize();

  runApp(SnorerApp(viewModel: viewModel, themeController: themeController));
}
