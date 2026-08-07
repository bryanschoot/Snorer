import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../domain/models/recording.dart';

class AudioPlaybackState {
  const AudioPlaybackState({
    this.recordingId,
    this.currentSeconds = 0,
    this.durationSeconds = 0,
    this.isPlaying = false,
    this.error,
  });

  final String? recordingId;
  final double currentSeconds;
  final double durationSeconds;
  final bool isPlaying;
  final String? error;

  double get progress => durationSeconds <= 0
      ? 0
      : (currentSeconds / durationSeconds).clamp(0, 1).toDouble();

  AudioPlaybackState copyWith({
    String? recordingId,
    bool clearRecording = false,
    double? currentSeconds,
    double? durationSeconds,
    bool? isPlaying,
    String? error,
    bool clearError = false,
  }) {
    return AudioPlaybackState(
      recordingId: clearRecording ? null : recordingId ?? this.recordingId,
      currentSeconds: currentSeconds ?? this.currentSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isPlaying: isPlaying ?? this.isPlaying,
      error: clearError ? null : error ?? this.error,
    );
  }
}

abstract interface class AudioPlaybackService {
  AudioPlaybackState get state;
  Stream<AudioPlaybackState> get states;
  Future<void> load(StoredRecording? recording);
  Future<void> toggle();
  Future<void> seekTo(double seconds);
  Future<void> pause();
  Future<void> dispose();
}

class JustAudioPlaybackService implements AudioPlaybackService {
  JustAudioPlaybackService() {
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _setState(
          _state.copyWith(currentSeconds: position.inMilliseconds / 1000),
        );
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        _setState(
          _state.copyWith(
            durationSeconds: duration?.inMilliseconds.toDouble() ?? 0,
          ),
        );
      }),
    );
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        _setState(
          _state.copyWith(
            isPlaying: playerState.playing,
            clearError: playerState.processingState != ProcessingState.idle,
          ),
        );
      }),
    );
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<AudioPlaybackState> _stateController =
      StreamController<AudioPlaybackState>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  AudioPlaybackState _state = const AudioPlaybackState();
  bool _disposed = false;

  @override
  AudioPlaybackState get state => _state;

  @override
  Stream<AudioPlaybackState> get states => _stateController.stream;

  void _setState(AudioPlaybackState state) {
    if (_disposed) return;
    _state = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  @override
  Future<void> load(StoredRecording? recording) async {
    if (recording == null) {
      await _player.stop();
      _setState(const AudioPlaybackState());
      return;
    }

    try {
      await _player.setFilePath(recording.audioPath);
      _setState(
        AudioPlaybackState(
          recordingId: recording.id,
          durationSeconds: recording.durationSeconds,
        ),
      );
    } catch (error) {
      _setState(
        AudioPlaybackState(
          recordingId: recording.id,
          durationSeconds: recording.durationSeconds,
          error: 'Afspelen voorbereiden lukt niet: ${_errorMessage(error)}',
        ),
      );
    }
  }

  @override
  Future<void> toggle() async {
    if (_state.recordingId == null) return;
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (error) {
      _setState(
        _state.copyWith(error: 'Afspelen lukt niet: ${_errorMessage(error)}'),
      );
    }
  }

  @override
  Future<void> seekTo(double seconds) async {
    if (_state.recordingId == null || _state.durationSeconds <= 0) return;
    try {
      final bounded = seconds.clamp(0, _state.durationSeconds).toDouble();
      await _player.seek(Duration(milliseconds: (bounded * 1000).round()));
    } catch (error) {
      _setState(
        _state.copyWith(
          error: 'Naar dit moment springen lukt niet: ${_errorMessage(error)}',
        ),
      );
    }
  }

  @override
  Future<void> pause() => _player.pause();

  String _errorMessage(Object error) => error is Exception
      ? error.toString().replaceFirst('Exception: ', '')
      : '$error';

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _stateController.close();
  }
}
