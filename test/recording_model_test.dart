import 'package:flutter_test/flutter_test.dart';
import 'package:snorer/domain/models/recording.dart';

void main() {
  test('round-trips stored recordings and detection events', () {
    final original = StoredRecording(
      id: 'night-1',
      audioPath: '/data/user/0/com.example/files/night.wav',
      startedAt: DateTime.parse('2026-08-07T22:30:00.000Z'),
      durationSeconds: 91.5,
      soundEvents: const [
        SoundEvent(
          id: 'snoring-0',
          kind: SoundEventKind.snoring,
          startSeconds: 0,
          endSeconds: 0.975,
          confidence: 0.77,
        ),
      ],
      fileSizeBytes: 2500000,
    );

    final decoded = StoredRecording.tryFromJson(original.toJson());

    expect(decoded, isNotNull);
    expect(decoded!.id, original.id);
    expect(decoded.audioPath, original.audioPath);
    expect(decoded.durationSeconds, original.durationSeconds);
    expect(decoded.soundEvents.single.kind, SoundEventKind.snoring);
    expect(decoded.fileSizeBytes, 2500000);
  });

  test('accepts the archived uri field and drops malformed events', () {
    final decoded = StoredRecording.tryFromJson({
      'id': 'legacy',
      'uri': '/tmp/legacy.wav',
      'startedAt': '2026-08-07T22:30:00Z',
      'durationSeconds': 12,
      'soundEvents': [
        {'id': 'bad', 'kind': 'unknown'},
        {
          'id': 'speech-0',
          'kind': 'speech',
          'startSeconds': 1,
          'endSeconds': 2,
          'confidence': 0.5,
        },
      ],
    });

    expect(decoded, isNotNull);
    expect(decoded!.audioPath, '/tmp/legacy.wav');
    expect(decoded.soundEvents, hasLength(1));
    expect(decoded.soundEvents.single.kind, SoundEventKind.speech);
    expect(decoded.fileSizeBytes, 0);
  });

  test('rejects records with invalid identity or duration', () {
    expect(
      StoredRecording.tryFromJson({
        'id': '',
        'uri': '/tmp/a.wav',
        'startedAt': '2026-08-07T22:30:00Z',
        'durationSeconds': 2,
      }),
      isNull,
    );
    expect(
      StoredRecording.tryFromJson({
        'id': 'bad-duration',
        'uri': '/tmp/a.wav',
        'startedAt': '2026-08-07T22:30:00Z',
        'durationSeconds': -1,
      }),
      isNull,
    );
  });
}
