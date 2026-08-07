// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../domain/models/recording.dart';
import '../../domain/services/sound_detection.dart';
import '../repositories/recording_repository.dart';
import 'foreground_recording_service.dart';
import 'sound_model_service.dart';

enum AudioRecordingStatus { idle, starting, recording, stopping, error }

enum SoundDetectionStatus { idle, loading, ready, unavailable }

class AudioRecordingState {
  const AudioRecordingState({
    this.permissionGranted,
    this.status = AudioRecordingStatus.idle,
    this.soundDetectionStatus = SoundDetectionStatus.idle,
    this.durationSeconds = 0,
    this.error,
  });

  final bool? permissionGranted;
  final AudioRecordingStatus status;
  final SoundDetectionStatus soundDetectionStatus;
  final double durationSeconds;
  final String? error;

  bool get isRecording => status == AudioRecordingStatus.recording;
  bool get isBusy =>
      status == AudioRecordingStatus.starting ||
      status == AudioRecordingStatus.stopping;

  AudioRecordingState copyWith({
    bool? permissionGranted,
    AudioRecordingStatus? status,
    SoundDetectionStatus? soundDetectionStatus,
    double? durationSeconds,
    String? error,
    bool clearError = false,
  }) {
    return AudioRecordingState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      status: status ?? this.status,
      soundDetectionStatus: soundDetectionStatus ?? this.soundDetectionStatus,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      error: clearError ? null : error ?? this.error,
    );
  }
}

abstract interface class AudioRecordingService {
  AudioRecordingState get state;
  Stream<AudioRecordingState> get states;
  Future<void> checkPermission();
  Future<RecordingStartResult> start();
  Future<RecordingDraft?> stop();
  Future<void> dispose();
}

enum RecordingStartResult { started, permissionDenied, failed }

class DeviceAudioRecordingService implements AudioRecordingService {
  DeviceAudioRecordingService({
    required RecordingRepository repository,
    required SoundModelService soundModel,
    required ForegroundRecordingController foregroundController,
  }) : _repository = repository,
       _soundModel = soundModel,
       _foregroundController = foregroundController;

  final RecordingRepository _repository;
  final SoundModelService _soundModel;
  final ForegroundRecordingController _foregroundController;
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<AudioRecordingState> _stateController =
      StreamController<AudioRecordingState>.broadcast();

  AudioRecordingState _state = const AudioRecordingState();
  StreamSubscription<Uint8List>? _pcmSubscription;
  Completer<void>? _streamDone;
  RandomAccessFile? _audioFile;
  String? _audioPath;
  DateTime? _startedAt;
  Timer? _durationTimer;
  Future<void> _writeQueue = Future<void>.value();
  Future<void> _analysisQueue = Future<void>.value();
  final List<double> _sampleBuffer = [];
  final List<SoundEvent> _soundEvents = [];
  int _processedSamples = 0;
  int _inputSampleRate = yamnetSampleRate;
  bool _disposed = false;

  @override
  AudioRecordingState get state => _state;

  @override
  Stream<AudioRecordingState> get states => _stateController.stream;

  void _setState(AudioRecordingState state) {
    if (_disposed) return;
    _state = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  @override
  Future<void> checkPermission() async {
    try {
      final granted = await _recorder.hasPermission(request: false);
      _setState(_state.copyWith(permissionGranted: granted));
    } catch (_) {
      _setState(_state.copyWith(permissionGranted: false));
    }
  }

  @override
  Future<RecordingStartResult> start() async {
    if (_state.isBusy || _state.isRecording) return RecordingStartResult.failed;

    _setState(
      _state.copyWith(
        status: AudioRecordingStatus.starting,
        soundDetectionStatus: SoundDetectionStatus.loading,
        durationSeconds: 0,
        clearError: true,
      ),
    );

    try {
      final permissionGranted = await _recorder.hasPermission();
      _setState(_state.copyWith(permissionGranted: permissionGranted));
      if (!permissionGranted) {
        _setState(
          _state.copyWith(
            status: AudioRecordingStatus.idle,
            soundDetectionStatus: SoundDetectionStatus.idle,
            error:
                'Geef Snorer toegang tot de microfoon om slaapgeluiden lokaal op te nemen.',
          ),
        );
        return RecordingStartResult.permissionDenied;
      }

      _resetSession();
      _startedAt = DateTime.now();
      _audioPath = await _repository.createAudioPath(_startedAt!);
      _audioFile = await File(_audioPath!).open(mode: FileMode.write);
      await _audioFile!.writeFrom(_waveHeader(0));

      try {
        await _soundModel.initialize();
        _setState(
          _state.copyWith(soundDetectionStatus: SoundDetectionStatus.ready),
        );
      } catch (_) {
        _setState(
          _state.copyWith(
            soundDetectionStatus: SoundDetectionStatus.unavailable,
          ),
        );
      }

      await _foregroundController.start();
      await _recorder.setOnConfigChanged((config) {
        if (config.sampleRate > 0) _inputSampleRate = config.sampleRate;
      });
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: yamnetSampleRate,
          numChannels: 1,
          streamBufferSize: 3200,
        ),
      );
      _streamDone = Completer<void>();
      _pcmSubscription = stream.listen(
        _handlePcmChunk,
        onError: (Object error, StackTrace stackTrace) {
          if (!(_streamDone?.isCompleted ?? true)) {
            _streamDone!.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!(_streamDone?.isCompleted ?? true)) _streamDone!.complete();
        },
        cancelOnError: false,
      );
      _durationTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final startedAt = _startedAt;
        if (startedAt == null) return;
        _setState(
          _state.copyWith(
            durationSeconds:
                DateTime.now().difference(startedAt).inMilliseconds / 1000,
          ),
        );
      });
      _setState(_state.copyWith(status: AudioRecordingStatus.recording));
      return RecordingStartResult.started;
    } catch (error) {
      await _cleanupFailedStart();
      _setState(
        _state.copyWith(
          status: AudioRecordingStatus.error,
          soundDetectionStatus: SoundDetectionStatus.unavailable,
          error: 'Opname starten lukt niet: ${_errorMessage(error)}',
        ),
      );
      return RecordingStartResult.failed;
    }
  }

  @override
  Future<RecordingDraft?> stop() async {
    if (!_state.isRecording || _state.status == AudioRecordingStatus.stopping) {
      return null;
    }

    _setState(_state.copyWith(status: AudioRecordingStatus.stopping));
    try {
      await _recorder.stop();
      final streamDone = _streamDone;
      if (streamDone != null) {
        await streamDone.future.timeout(const Duration(seconds: 5));
      }
      await _pcmSubscription?.cancel();
      _flushSoundDetection();
      await _analysisQueue;
      await _writeQueue;

      final path = _audioPath;
      final startedAt = _startedAt;
      if (path == null || startedAt == null) {
        throw StateError('De opname heeft geen geldig bestand opgeleverd.');
      }
      final durationSeconds =
          DateTime.now().difference(startedAt).inMilliseconds / 1000;
      await _finalizeWaveFile();
      await _foregroundController.stop();
      final draft = RecordingDraft(
        audioPath: path,
        startedAt: startedAt,
        durationSeconds: durationSeconds.clamp(0.1, double.infinity).toDouble(),
        soundEvents: List<SoundEvent>.unmodifiable(_soundEvents),
      );
      _resetSession();
      _setState(
        AudioRecordingState(
          permissionGranted: _state.permissionGranted,
          status: AudioRecordingStatus.idle,
          soundDetectionStatus: _state.soundDetectionStatus,
          durationSeconds: draft.durationSeconds,
        ),
      );
      return draft;
    } catch (error) {
      await _cleanupFailedStart();
      _setState(
        _state.copyWith(
          status: AudioRecordingStatus.error,
          error: 'Opname stoppen lukt niet: ${_errorMessage(error)}',
        ),
      );
      return null;
    }
  }

  void _resetSession() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _sampleBuffer.clear();
    _soundEvents.clear();
    _processedSamples = 0;
    _inputSampleRate = yamnetSampleRate;
    _analysisQueue = Future<void>.value();
    _writeQueue = Future<void>.value();
  }

  void _handlePcmChunk(Uint8List bytes) {
    final samples = <double>[];
    final data = ByteData.sublistView(bytes);
    for (var offset = 0; offset + 1 < data.lengthInBytes; offset += 2) {
      samples.add(data.getInt16(offset, Endian.little) / 32768.0);
    }
    if (samples.isEmpty) return;

    _writeQueue = _writeQueue.then((_) async {
      await _audioFile?.writeFrom(bytes);
    });

    final normalized = resampleLinear(samples, _inputSampleRate);
    _sampleBuffer.addAll(normalized);
    while (_sampleBuffer.length >= yamnetWindowSamples) {
      final frame = _sampleBuffer.sublist(0, yamnetWindowSamples);
      _sampleBuffer.removeRange(0, yamnetWindowSamples);
      final startSeconds = _processedSamples / yamnetSampleRate;
      _processedSamples += yamnetWindowSamples;
      _enqueueFrame(frame, startSeconds);
    }
  }

  void _enqueueFrame(List<double> frame, double startSeconds) {
    if (!_soundModel.isReady) return;
    final copiedFrame = List<double>.from(frame, growable: false);
    _analysisQueue = _analysisQueue.then((_) async {
      try {
        final scores = await _soundModel.classify(copiedFrame);
        final classification = classifyYamnetScores(scores);
        if (classification != null) {
          final next = appendSoundEvent(
            _soundEvents,
            classification,
            startSeconds,
          );
          _soundEvents
            ..clear()
            ..addAll(next);
        }
      } catch (_) {
        _setState(
          _state.copyWith(
            soundDetectionStatus: SoundDetectionStatus.unavailable,
          ),
        );
      }
    });
  }

  void _flushSoundDetection() {
    final frame = createYamnetFrame(_sampleBuffer);
    if (frame != null) {
      _enqueueFrame(frame, _processedSamples / yamnetSampleRate);
    }
    _sampleBuffer.clear();
  }

  Future<void> _finalizeWaveFile() async {
    final file = _audioFile;
    if (file == null) return;
    await _writeQueue;
    final dataLength = await file.length() - 44;
    await file.setPosition(0);
    await file.writeFrom(_waveHeader(dataLength < 0 ? 0 : dataLength));
    await file.flush();
    await file.close();
    _audioFile = null;
  }

  List<int> _waveHeader(int dataLength) {
    final bytes = Uint8List(44);
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    data.setUint32(4, 36 + dataLength, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, yamnetSampleRate, Endian.little);
    data.setUint32(28, yamnetSampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    bytes.setRange(36, 40, 'data'.codeUnits);
    data.setUint32(40, dataLength, Endian.little);
    return bytes;
  }

  Future<void> _cleanupFailedStart() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
    try {
      await _foregroundController.stop();
    } catch (_) {}
    await _audioFile?.close();
    _audioFile = null;
    final path = _audioPath;
    if (path != null) {
      try {
        await _repository.deleteAudioFile(path);
      } catch (_) {}
    }
    _audioPath = null;
    _startedAt = null;
    _resetSession();
  }

  String _errorMessage(Object error) => error is Exception
      ? error.toString().replaceFirst('Exception: ', '')
      : '$error';

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _durationTimer?.cancel();
    await _pcmSubscription?.cancel();
    await _audioFile?.close();
    await _recorder.dispose();
    _soundModel.dispose();
    await _stateController.close();
  }
}
