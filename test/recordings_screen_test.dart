import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snorer/core/theme/app_theme.dart';
import 'package:snorer/data/repositories/recording_repository.dart';
import 'package:snorer/data/services/audio_playback_service.dart';
import 'package:snorer/data/services/audio_recording_service.dart';
import 'package:snorer/domain/models/recording.dart';
import 'package:snorer/presentation/recordings/recordings_screen.dart';
import 'package:snorer/presentation/recordings/recordings_view_model.dart';

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
    expect(find.text('1 sessie'), findsOneWidget);
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
}

RecordingsViewModel _createViewModel(List<StoredRecording> recordings) {
  return RecordingsViewModel(
    repository: _FakeRepository(recordings),
    recorder: _FakeRecorder(),
    player: _FakePlayer(),
  );
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
  Future<RecordingDraft?> stop() async => null;

  @override
  Future<void> dispose() => _states.close();
}

class _FakePlayer implements AudioPlaybackService {
  final StreamController<AudioPlaybackState> _states =
      StreamController.broadcast();
  AudioPlaybackState _state = const AudioPlaybackState();

  @override
  AudioPlaybackState get state => _state;

  @override
  Stream<AudioPlaybackState> get states => _states.stream;

  @override
  Future<void> load(StoredRecording? recording) async {
    _state = AudioPlaybackState(
      recordingId: recording?.id,
      durationSeconds: recording?.durationSeconds ?? 0,
    );
    _states.add(_state);
  }

  @override
  Future<void> toggle() async {}

  @override
  Future<void> seekTo(double seconds) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() => _states.close();
}
