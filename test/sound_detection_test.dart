import 'package:flutter_test/flutter_test.dart';
import 'package:snorer/domain/models/recording.dart';
import 'package:snorer/domain/services/sound_detection.dart';

void main() {
  test('classifies the strongest YAMNet target above the threshold', () {
    final scores = List<double>.filled(521, 0)
      ..[0] = 0.41
      ..[38] = 0.79;

    final result = classifyYamnetScores(scores);

    expect(result?.kind, SoundEventKind.snoring);
    expect(result?.confidence, 0.79);
  });

  test('ignores frames without a confident speech or snoring score', () {
    final result = classifyYamnetScores(List<double>.filled(521, 0.31));

    expect(result, isNull);
  });

  test(
    'merges adjacent events of the same kind and preserves peak confidence',
    () {
      final first = appendSoundEvent(
        const [],
        const SoundClassification(
          kind: SoundEventKind.speech,
          confidence: 0.58,
        ),
        0,
      );
      final merged = appendSoundEvent(
        first,
        const SoundClassification(
          kind: SoundEventKind.speech,
          confidence: 0.86,
        ),
        1.2,
      );

      expect(merged, hasLength(1));
      expect(merged.single.startSeconds, 0);
      expect(merged.single.endSeconds, closeTo(2.175, 0.0001));
      expect(merged.single.confidence, 0.86);
    },
  );

  test('creates a padded YAMNet frame only when enough samples exist', () {
    expect(createYamnetFrame(List<double>.filled(3899, 0)), isNull);

    final frame = createYamnetFrame(List<double>.filled(4000, 0.25));

    expect(frame, hasLength(yamnetWindowSamples));
    expect(frame!.first, 0.25);
    expect(frame[3999], 0.25);
    expect(frame.last, 0);
  });
}
