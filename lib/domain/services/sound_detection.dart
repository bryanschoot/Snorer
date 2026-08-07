import '../models/recording.dart';

const yamnetSampleRate = 16000;
const yamnetWindowSamples = 15600;
const yamnetWindowSeconds = yamnetWindowSamples / yamnetSampleRate;

const _speechIndex = 0;
const _snoringIndex = 38;
const _minimumConfidence = 0.32;
const _mergeGapSeconds = 1.5;

class SoundClassification {
  const SoundClassification({required this.kind, required this.confidence});

  final SoundEventKind kind;
  final double confidence;
}

SoundClassification? classifyYamnetScores(List<double> scores) {
  final speechScore = scores.length > _speechIndex ? scores[_speechIndex] : 0.0;
  final snoringScore = scores.length > _snoringIndex
      ? scores[_snoringIndex]
      : 0.0;

  if (speechScore < _minimumConfidence && snoringScore < _minimumConfidence) {
    return null;
  }

  if (snoringScore >= speechScore) {
    return SoundClassification(
      kind: SoundEventKind.snoring,
      confidence: snoringScore,
    );
  }

  return SoundClassification(
    kind: SoundEventKind.speech,
    confidence: speechScore,
  );
}

List<SoundEvent> appendSoundEvent(
  List<SoundEvent> events,
  SoundClassification classification,
  double startSeconds,
) {
  final endSeconds = startSeconds + yamnetWindowSeconds;
  final previous = events.isEmpty ? null : events.last;

  if (previous != null &&
      previous.kind == classification.kind &&
      startSeconds <= previous.endSeconds + _mergeGapSeconds) {
    return [
      ...events.take(events.length - 1),
      previous.copyWith(
        endSeconds: endSeconds > previous.endSeconds
            ? endSeconds
            : previous.endSeconds,
        confidence: classification.confidence > previous.confidence
            ? classification.confidence
            : previous.confidence,
      ),
    ];
  }

  return [
    ...events,
    SoundEvent(
      id: '${classification.kind.jsonValue}-${(startSeconds * 1000).round()}',
      kind: classification.kind,
      startSeconds: startSeconds,
      endSeconds: endSeconds,
      confidence: classification.confidence.clamp(0, 1).toDouble(),
    ),
  ];
}

List<double>? createYamnetFrame(Iterable<double> samples) {
  final source = samples is List<double>
      ? samples
      : samples.toList(growable: false);
  if (source.length < yamnetWindowSamples ~/ 4) return null;

  final frame = List<double>.filled(yamnetWindowSamples, 0);
  final copyLength = source.length < yamnetWindowSamples
      ? source.length
      : yamnetWindowSamples;
  for (var index = 0; index < copyLength; index += 1) {
    frame[index] = source[index];
  }
  return frame;
}

List<double> resampleLinear(List<double> samples, int sourceSampleRate) {
  if (samples.isEmpty ||
      sourceSampleRate <= 0 ||
      sourceSampleRate == yamnetSampleRate) {
    return samples;
  }

  final ratio = yamnetSampleRate / sourceSampleRate;
  final outputLength = (samples.length * ratio).round().clamp(
    1,
    samples.length * 4,
  );
  final resampled = List<double>.filled(outputLength, 0);
  for (var index = 0; index < outputLength; index += 1) {
    final sourceIndex = index / ratio;
    final leftIndex = sourceIndex.floor().clamp(0, samples.length - 1);
    final rightIndex = (leftIndex + 1).clamp(0, samples.length - 1);
    final mix = sourceIndex - leftIndex;
    resampled[index] =
        samples[leftIndex] * (1 - mix) + samples[rightIndex] * mix;
  }
  return resampled;
}
