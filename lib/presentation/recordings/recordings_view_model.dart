// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../core/errors/snorer_error.dart';
import '../../data/services/audio_playback_service.dart';
import '../../data/services/audio_recording_service.dart';
import '../../data/repositories/recording_repository.dart';
import '../../domain/models/recording.dart';

class RecordingsViewModel extends ChangeNotifier {
  RecordingsViewModel({
    required RecordingRepository repository,
    required AudioRecordingService recorder,
    required AudioPlaybackService player,
  }) : _repository = repository,
       _recorder = recorder,
       _player = player {
    _subscriptions.add(
      _recorder.states.listen((state) {
        _recorderState = state;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.states.listen((state) {
        _playerState = state;
        notifyListeners();
      }),
    );
  }

  final RecordingRepository _repository;
  final AudioRecordingService _recorder;
  final AudioPlaybackService _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<StoredRecording> _recordings = const [];
  AudioRecordingState _recorderState = const AudioRecordingState();
  AudioPlaybackState _playerState = const AudioPlaybackState();
  String? _selectedId;
  SnorerError? _libraryError;
  bool _isHydrated = false;
  bool _disposed = false;
  double _completedDurationSeconds = 0;

  List<StoredRecording> get recordings => List.unmodifiable(_recordings);
  AudioRecordingState get recorderState => _recorderState;
  AudioPlaybackState get playerState => _playerState;
  double get displayedDurationSeconds {
    final stateDuration = _recorderState.durationSeconds;
    if (_recorderState.isBusy || _recorderState.isRecording) {
      return stateDuration;
    }
    return stateDuration > 0 ? stateDuration : _completedDurationSeconds;
  }

  bool get isHydrated => _isHydrated;
  SnorerError? get error =>
      _recorderState.error ?? _playerState.error ?? _libraryError;
  StoredRecording? get selectedRecording {
    if (_recordings.isEmpty) return null;
    return _recordings
            .where((recording) => recording.id == _selectedId)
            .firstOrNull ??
        _recordings.first;
  }

  Future<void> initialize() async {
    await _recorder.checkPermission();
    try {
      _recordings = await _repository.loadRecordings();
      _selectedId = _recordings.firstOrNull?.id;
      _libraryError = null;
    } catch (_) {
      _libraryError = const SnorerError(SnorerErrorCode.libraryLoad);
    } finally {
      _isHydrated = true;
      notifyListeners();
    }
    await _loadSelectedPlayer();
  }

  Future<void> startRecording() async {
    _completedDurationSeconds = 0;
    notifyListeners();
    await _player.pause();
    final result = await _recorder.start();
    if (result == RecordingStartResult.permissionDenied) {
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    final draft = await _recorder.stop();
    if (draft == null) {
      notifyListeners();
      return;
    }
    _completedDurationSeconds = draft.durationSeconds;

    final recording = StoredRecording(
      id: _createRecordingId(),
      audioPath: draft.audioPath,
      startedAt: draft.startedAt,
      durationSeconds: draft.durationSeconds,
      soundEvents: draft.soundEvents,
      label: null,
    );
    _recordings = [recording, ..._recordings];
    _selectedId = recording.id;
    _libraryError = null;
    notifyListeners();
    await _persist();
    await _loadSelectedPlayer();
  }

  void selectRecording(String id) {
    if (!_recordings.any((recording) => recording.id == id)) return;
    if (_selectedId == id) return;
    unawaited(_player.pause());
    _selectedId = id;
    notifyListeners();
    unawaited(_loadSelectedPlayer());
  }

  Future<void> toggleLabel(String id, RecordingLabel label) async {
    _recordings = _recordings
        .map(
          (recording) => recording.id == id
              ? recording.copyWith(
                  clearLabel: recording.label == label,
                  label: recording.label == label ? null : label,
                )
              : recording,
        )
        .toList(growable: false);
    notifyListeners();
    await _persist();
  }

  Future<bool> deleteRecording(String id) async {
    final recording = _recordings
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    if (recording == null) return false;

    try {
      await _repository.deleteAudioFile(recording.audioPath);
      _recordings = _recordings
          .where((candidate) => candidate.id != id)
          .toList(growable: false);
      if (_selectedId == id) {
        _selectedId = _recordings.firstOrNull?.id;
        await _loadSelectedPlayer();
      }
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      _libraryError = const SnorerError(SnorerErrorCode.deleteRecording);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllRecordings() async {
    try {
      for (final recording in _recordings) {
        await _repository.deleteAudioFile(recording.audioPath);
      }
      _recordings = const [];
      _selectedId = null;
      await _player.load(null);
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      _libraryError = const SnorerError(SnorerErrorCode.deleteAllRecordings);
      notifyListeners();
      return false;
    }
  }

  Future<void> togglePlayback() => _player.toggle();
  Future<void> seekTo(double seconds) => _player.seekTo(seconds);
  Future<void> pausePlayback() => _player.pause();

  Future<void> _loadSelectedPlayer() async {
    await _player.load(selectedRecording);
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _repository.saveRecordings(_recordings);
      _libraryError = null;
    } catch (_) {
      _libraryError = const SnorerError(SnorerErrorCode.persistRecording);
    }
  }

  String _createRecordingId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_recordings.length}';

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
