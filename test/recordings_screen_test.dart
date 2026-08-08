import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snorer/app.dart';
import 'package:snorer/core/localization/snorer_language.dart';
import 'package:snorer/core/theme/app_theme.dart';
import 'package:snorer/data/repositories/recording_repository.dart';
import 'package:snorer/data/services/audio_playback_service.dart';
import 'package:snorer/data/services/audio_recording_service.dart';
import 'package:snorer/data/services/app_update_service.dart';
import 'package:snorer/data/services/language_preferences.dart';
import 'package:snorer/data/services/theme_preferences.dart';
import 'package:snorer/domain/models/recording.dart';
import 'package:snorer/presentation/recordings/recordings_screen.dart';
import 'package:snorer/presentation/recordings/recordings_view_model.dart';
import 'package:snorer/presentation/update/update_controller.dart';
import 'package:snorer/presentation/settings/language_controller.dart';
import 'package:snorer/presentation/settings/settings_screen.dart';
import 'package:snorer/presentation/settings/theme_controller.dart';

void main() {
  testWidgets('shows a local recording and changes its manual label', (
    tester,
  ) async {
    final recording = StoredRecording(
      id: 'night-1',
      audioPath: '/tmp/night-1.wav',
      startedAt: DateTime.parse('2026-08-07T22:30:00Z'),
      durationSeconds: 185,
      soundEvents: const [],
      label: null,
    );
    final viewModel = _createViewModel([recording]);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.text('Lokale opnames'),
      500,
      scrollable: scrollable,
    );
    expect(find.text('Lokale opnames'), findsOneWidget);
    expect(find.text('1 nacht'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('3m 05s'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('3m 05s'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Snurken'),
      300,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Snurken'));
    await tester.pump();

    expect(viewModel.recordings.single.label, RecordingLabel.snoring);
  });
  testWidgets('keeps recordings below system bars', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: 24),
          ),
          child: RecordingsScreen(viewModel: _createViewModel(const [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listTop = tester.getTopLeft(
      find.byKey(const Key('recordings_scroll_view')),
    );
    expect(listTop.dy, greaterThanOrEqualTo(24));
  });
  testWidgets('controls playback from the waveform', (tester) async {
    final recording = StoredRecording(
      id: 'night-1',
      audioPath: '/tmp/night-1.wav',
      startedAt: DateTime.parse('2026-08-07T22:30:00Z'),
      durationSeconds: 185,
      soundEvents: const [],
      label: null,
    );
    final player = _FakePlayer();
    final viewModel = _createViewModel([recording], player: player);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.byKey(const Key('recording_waveform')),
      500,
      scrollable: scrollable,
    );

    expect(find.byKey(const Key('recording_waveform')), findsOneWidget);
    expect(find.byKey(const Key('toggle_playback')), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.byKey(const Key('recording_playhead')), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle_playback')));
    expect(player.toggleCalls, 1);

    final waveformCenter = tester.getCenter(
      find.byKey(const Key('recording_waveform')),
    );
    await tester.tapAt(waveformCenter);
    expect(player.lastSeekSeconds, closeTo(92.5, 0.1));
    expect(
      tester.widget<Text>(find.byKey(const Key('waveform_start_time'))).data,
      '00:00',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('waveform_end_time'))).data,
      '03:05',
    );
  });
  testWidgets('keeps detected sound markers with the waveform', (
    tester,
  ) async {
    final recording = StoredRecording(
      id: 'night-1',
      audioPath: '/tmp/night-1.wav',
      startedAt: DateTime.parse('2026-08-07T22:30:00Z'),
      durationSeconds: 185,
      soundEvents: const [
        SoundEvent(
          id: 'snore-1',
          kind: SoundEventKind.snoring,
          startSeconds: 10,
          endSeconds: 12,
          confidence: 0.9,
        ),
        SoundEvent(
          id: 'speech-1',
          kind: SoundEventKind.speech,
          startSeconds: 20,
          endSeconds: 22,
          confidence: 0.8,
        ),
      ],
      label: null,
    );
    final player = _FakePlayer();
    final viewModel = _createViewModel([recording], player: player);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.byKey(const Key('recording_waveform')),
      500,
      scrollable: scrollable,
    );

    expect(find.byKey(const Key('recording_waveform')), findsOneWidget);
    expect(find.byKey(const Key('previous_sound_event')), findsOneWidget);
    expect(find.byKey(const Key('next_sound_event')), findsOneWidget);
    expect(find.text('1 snurkmoment'), findsOneWidget);
    expect(find.text('1 praatmoment'), findsOneWidget);
    await tester.tap(find.byKey(const Key('event_filter_snoring')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('next_sound_event')));
    expect(player.lastSeekSeconds, 10);

    await tester.tap(find.byKey(const Key('event_filter_speech')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('next_sound_event')));
    expect(player.lastSeekSeconds, 20);
  });


  testWidgets('switches the recorder card to stop mode after starting', (
    tester,
  ) async {
    final viewModel = _createViewModel(const []);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start_recording')));
    await tester.pump();

    expect(find.byKey(const Key('stop_recording')), findsOneWidget);
    expect(find.text('Opname voor vannacht'), findsOneWidget);
  });
  testWidgets('keeps the completed recording time after stopping', (
    tester,
  ) async {
    final recorder = _FakeRecorder()
      ..stopDraft = RecordingDraft(
        audioPath: '/tmp/stopped-night.wav',
        startedAt: DateTime.parse('2026-08-07T22:30:00Z'),
        durationSeconds: 125,
        soundEvents: const [],
      );
    final viewModel = _createViewModel(const [], recorder: recorder);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start_recording')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stop_recording')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('recording_timer'))).data,
      '02:05',
    );
  });
  testWidgets('exposes the settings action', (tester) async {
    var opened = false;
    final viewModel = _createViewModel(const []);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(
          viewModel: viewModel,
          onOpenSettings: () => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_settings')));
    expect(opened, isTrue);
  });
  testWidgets('shows an orange settings indicator for available updates', (
    tester,
  ) async {
    final updateController = UpdateController(
      currentVersion: '0.2.9',
      service: _FakeUpdateService(
        AppRelease(
          tagName: 'v0.3.0',
          version: AppVersion(0, 3, 0),
          releaseUrl: Uri.parse(
            'https://github.com/bryanschoot/Snorer/releases/tag/v0.3.0',
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(
          viewModel: _createViewModel(const []),
          updateController: updateController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await updateController.checkForUpdate();
    await tester.pump();

    expect(find.byKey(const Key('settings_update_indicator')), findsOneWidget);
    expect(find.byKey(const Key('open_update_release')), findsNothing);
  });
  testWidgets('keeps privacy details out of the recordings overview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(),
        home: RecordingsScreen(viewModel: _createViewModel(const [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privé en lokaal'), findsNothing);
  });
  testWidgets('opens settings and renders Material icons from the full app', (
    tester,
  ) async {
    final themeController = ThemeController(
      preferences: _MemoryThemePreferences(),
    );
    final languageController = LanguageController(
      preferences: _MemoryLanguagePreferences(),
    );
    await themeController.initialize();
    await languageController.initialize();

    await tester.pumpWidget(
      SnorerApp(
        viewModel: _createViewModel(const []),
        themeController: themeController,
        languageController: languageController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
  });
}

RecordingsViewModel _createViewModel(
  List<StoredRecording> recordings, {
  AudioPlaybackService? player,
  AudioRecordingService? recorder,
}) {
  return RecordingsViewModel(
    repository: _FakeRepository(recordings),
    recorder: recorder ?? _FakeRecorder(),
    player: player ?? _FakePlayer(),
  );
}

class _MemoryThemePreferences implements ThemePreferences {
  @override
  Future<SnorerThemeMode> load() async => SnorerThemeMode.dark;

  @override
  Future<void> save(SnorerThemeMode mode) async {}
}

class _MemoryLanguagePreferences implements LanguagePreferences {
  @override
  Future<SnorerLanguage> load() async => SnorerLanguage.dutch;

  @override
  Future<void> save(SnorerLanguage language) async {}
}

class _FakeRepository implements RecordingRepository {
  _FakeRepository(this._recordings);

  final List<StoredRecording> _recordings;

  @override
  Future<List<StoredRecording>> loadRecordings() async => List.of(_recordings);

  @override
  Future<void> saveRecordings(List<StoredRecording> recordings) async {}

  @override
  Future<String> createAudioPath(DateTime startedAt) async =>
      '/tmp/${startedAt.microsecondsSinceEpoch}.wav';

  @override
  Future<void> deleteAudioFile(String path) async {}
}

class _FakeRecorder implements AudioRecordingService {
  RecordingDraft? stopDraft;
  final StreamController<AudioRecordingState> _states =
      StreamController.broadcast();
  AudioRecordingState _state = const AudioRecordingState(
    permissionGranted: true,
  );

  @override
  AudioRecordingState get state => _state;

  @override
  Stream<AudioRecordingState> get states => _states.stream;

  @override
  Future<void> checkPermission() async {}

  @override
  Future<RecordingStartResult> start() async {
    _state = const AudioRecordingState(
      permissionGranted: true,
      status: AudioRecordingStatus.recording,
      soundDetectionStatus: SoundDetectionStatus.ready,
    );
    _states.add(_state);
    return RecordingStartResult.started;
  }

  @override
  Future<RecordingDraft?> stop() async {
    final draft = stopDraft;
    _state = const AudioRecordingState(
      permissionGranted: true,
      status: AudioRecordingStatus.idle,
    );
    _states.add(_state);
    return draft;
  }

  @override
  Future<void> dispose() => _states.close();
}

class _FakePlayer implements AudioPlaybackService {
  final StreamController<AudioPlaybackState> _states =
      StreamController.broadcast();
  AudioPlaybackState _state = const AudioPlaybackState();
  int toggleCalls = 0;
  double? lastSeekSeconds;

  @override
  AudioPlaybackState get state => _state;

  @override
  Stream<AudioPlaybackState> get states => _states.stream;
  void emit(AudioPlaybackState state) {
    _state = state;
    _states.add(state);
  }

  @override
  Future<void> load(StoredRecording? recording) async {
    _state = AudioPlaybackState(
      recordingId: recording?.id,
      durationSeconds: recording?.durationSeconds ?? 0,
    );
    _states.add(_state);
  }

  @override
  Future<void> toggle() async => toggleCalls += 1;
  @override
  Future<void> seekTo(double seconds) async {
    lastSeekSeconds = seconds;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() => _states.close();
}
class _FakeUpdateService implements AppUpdateService {
  const _FakeUpdateService(this.release);

  final AppRelease? release;

  @override
  Future<AppRelease?> checkForUpdate(String currentVersion) async => release;

  @override
  Future<ApkInstallResult> install(AppRelease release) async =>
      ApkInstallResult.started;

  @override
  void dispose() {}
}
