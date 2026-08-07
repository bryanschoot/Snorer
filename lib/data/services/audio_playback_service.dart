import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import '../../core/errors/snorer_error.dart';
import '../../domain/models/recording.dart';

class AudioPlaybackState {
  const AudioPlaybackState({
    this.recordingId,
    this.currentSeconds = 0,
    this.durationSeconds = 0,
    this.isPlaying = false,
    this.waveform = const [],
    this.error,
  });

  final String? recordingId;
  final double currentSeconds;
  final double durationSeconds;
  final bool isPlaying;
  final List<double> waveform;
  final SnorerError? error;

  double get progress => durationSeconds <= 0
      ? 0
      : (currentSeconds / durationSeconds).clamp(0, 1).toDouble();

  AudioPlaybackState copyWith({
    String? recordingId,
    bool clearRecording = false,
    double? currentSeconds,
    double? durationSeconds,
    bool? isPlaying,
    List<double>? waveform,
    SnorerError? error,
    bool clearError = false,
  }) {
    return AudioPlaybackState(
      recordingId: clearRecording ? null : recordingId ?? this.recordingId,
      currentSeconds: currentSeconds ?? this.currentSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isPlaying: isPlaying ?? this.isPlaying,
      waveform: waveform ?? this.waveform,
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
        final seconds = duration?.inMilliseconds.toDouble() ?? 0;
        _setState(
          _state.copyWith(
            durationSeconds: seconds > 0 ? seconds : _state.durationSeconds,
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
  int _loadGeneration = 0;

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
    final loadGeneration = ++_loadGeneration;
    if (recording == null) {
      await _player.stop();
      _setState(const AudioPlaybackState());
      return;
    }

    try {
      await _player.setFilePath(recording.audioPath);
      if (_disposed || loadGeneration != _loadGeneration) return;
      _setState(
        AudioPlaybackState(
          recordingId: recording.id,
          durationSeconds: recording.durationSeconds,
        ),
      );

      var waveform = const <double>[];
      try {
        waveform = await _readWaveform(recording.audioPath);
      } catch (_) {
        // Playback remains available even when an older or malformed file
        // cannot provide waveform samples.
      }
      if (_disposed ||
          loadGeneration != _loadGeneration ||
          _state.recordingId != recording.id) {
        return;
      }
      _setState(_state.copyWith(waveform: waveform));
    } catch (error) {
      _setState(
        AudioPlaybackState(
          recordingId: recording.id,
          durationSeconds: recording.durationSeconds,
          error: SnorerError(
            SnorerErrorCode.playbackLoad,
            detail: _errorMessage(error),
          ),
        ),
      );
    }
  }

  Future<List<double>> _readWaveform(String path) async {
    const headerBytes = 44;
    const bucketCount = 96;
    const windowsPerBucket = 4;
    const samplesPerWindow = 256;
    final file = await File(path).open();
    try {
      final dataLength = await file.length() - headerBytes;
      final sampleCount = dataLength ~/ 2;
      if (sampleCount <= 0) return const [];

      final peaks = List<double>.filled(bucketCount, 0);
      for (var bucket = 0; bucket < bucketCount; bucket += 1) {
        final start = bucket * sampleCount ~/ bucketCount;
        final end = (bucket + 1) * sampleCount ~/ bucketCount;
        final span = end > start ? end - start : 1;
        for (var window = 0; window < windowsPerBucket; window += 1) {
          final windowStart = start + span * window ~/ windowsPerBucket;
          final remaining = end - windowStart;
          if (remaining <= 0) continue;
          final samplesToRead = remaining < samplesPerWindow
              ? remaining
              : samplesPerWindow;
          await file.setPosition(headerBytes + windowStart * 2);
          final bytes = await file.read(samplesToRead * 2);
          final data = ByteData.sublistView(bytes);
          for (var offset = 0;
              offset + 1 < data.lengthInBytes;
              offset += 2) {
            final amplitude =
                (data.getInt16(offset, Endian.little).abs() / 32768)
                    .clamp(0, 1)
                    .toDouble();
            if (amplitude > peaks[bucket]) peaks[bucket] = amplitude;
          }
        }
      }

      var maximum = 0.0;
      for (final peak in peaks) {
        if (peak > maximum) maximum = peak;
      }
      if (maximum <= 0) return const [];
      return List<double>.unmodifiable(
        peaks.map(
          (peak) => (peak / maximum).clamp(0.08, 1.0).toDouble(),
        ),
      );
    } finally {
      await file.close();
    }
  }

  @override
  Future<void> toggle() async {
    if (_state.recordingId == null) return;
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (error) {
      _setState(
        _state.copyWith(
          error: SnorerError(
            SnorerErrorCode.playback,
            detail: _errorMessage(error),
          ),
        ),
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
          error: SnorerError(
            SnorerErrorCode.playbackSeek,
            detail: _errorMessage(error),
          ),
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
