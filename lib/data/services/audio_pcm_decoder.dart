import 'package:flutter/services.dart';

class DecodedPcmFile {
  const DecodedPcmFile({
    required this.path,
    required this.sampleRate,
    required this.channels,
  });

  final String path;
  final int sampleRate;
  final int channels;
}

abstract interface class AudioPcmDecoder {
  Future<DecodedPcmFile> decode(String path);
}

class MethodChannelAudioPcmDecoder implements AudioPcmDecoder {
  const MethodChannelAudioPcmDecoder();

  static const _channel = MethodChannel(
    'com.bryanschoot.snorer/audio_decoder',
  );

  @override
  Future<DecodedPcmFile> decode(String path) async {
    final raw = await _channel.invokeMethod<Object?>('decodeToPcm', {
      'path': path,
    });
    if (raw is! Map) {
      throw StateError('De audio-decoder gaf geen geldig resultaat terug.');
    }

    final result = Map<Object?, Object?>.from(raw);
    final decodedPath = result['path'];
    final sampleRate = result['sampleRate'];
    final channels = result['channels'];
    if (decodedPath is! String ||
        decodedPath.isEmpty ||
        sampleRate is! int ||
        sampleRate <= 0 ||
        channels is! int ||
        channels <= 0) {
      throw StateError('De audio-decoder gaf ongeldige PCM-metadata terug.');
    }

    return DecodedPcmFile(
      path: decodedPath,
      sampleRate: sampleRate,
      channels: channels,
    );
  }
}
