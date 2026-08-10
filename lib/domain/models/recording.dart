
enum SoundEventKind {
  snoring,
  speech;

  String get jsonValue => switch (this) {
    SoundEventKind.snoring => 'snoring',
    SoundEventKind.speech => 'speech',
  };

  String get displayName => switch (this) {
    SoundEventKind.snoring => 'Snurken',
    SoundEventKind.speech => 'Praten',
  };

  static SoundEventKind? fromJson(Object? value) => switch (value) {
    'snoring' => SoundEventKind.snoring,
    'speech' => SoundEventKind.speech,
    _ => null,
  };
}

class SoundEvent {
  const SoundEvent({
    required this.id,
    required this.kind,
    required this.startSeconds,
    required this.endSeconds,
    required this.confidence,
  });

  final String id;
  final SoundEventKind kind;
  final double startSeconds;
  final double endSeconds;
  final double confidence;

  SoundEvent copyWith({
    String? id,
    SoundEventKind? kind,
    double? startSeconds,
    double? endSeconds,
    double? confidence,
  }) {
    return SoundEvent(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.jsonValue,
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
    'confidence': confidence,
  };

  static SoundEvent? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final kind = SoundEventKind.fromJson(value['kind']);
    final start = _finiteDouble(value['startSeconds']);
    final end = _finiteDouble(value['endSeconds']);
    final confidence = _finiteDouble(value['confidence']);
    final id = value['id'];
    if (id is! String ||
        id.isEmpty ||
        kind == null ||
        start == null ||
        end == null ||
        confidence == null ||
        start < 0 ||
        end < start) {
      return null;
    }
    return SoundEvent(
      id: id,
      kind: kind,
      startSeconds: start,
      endSeconds: end,
      confidence: confidence.clamp(0, 1),
    );
  }

  static double? _finiteDouble(Object? value) {
    final number = value is num ? value.toDouble() : double.nan;
    return number.isFinite ? number : null;
  }
}

class RecordingDraft {
  const RecordingDraft({
    required this.audioPath,
    required this.startedAt,
    required this.durationSeconds,
    required this.soundEvents,
  });

  final String audioPath;
  final DateTime startedAt;
  final double durationSeconds;
  final List<SoundEvent> soundEvents;
}

class StoredRecording {
  const StoredRecording({
    required this.id,
    required this.audioPath,
    required this.startedAt,
    required this.durationSeconds,
    required this.soundEvents,
    this.fileSizeBytes = 0,
  });

  final String id;
  final String audioPath;
  final DateTime startedAt;
  final double durationSeconds;
  final List<SoundEvent> soundEvents;
  final int fileSizeBytes;

  StoredRecording copyWith({
    String? id,
    String? audioPath,
    DateTime? startedAt,
    double? durationSeconds,
    List<SoundEvent>? soundEvents,
    int? fileSizeBytes,
  }) {
    return StoredRecording(
      id: id ?? this.id,
      audioPath: audioPath ?? this.audioPath,
      startedAt: startedAt ?? this.startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      soundEvents: soundEvents ?? this.soundEvents,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'uri': audioPath,
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'soundEvents': soundEvents.map((event) => event.toJson()).toList(),
    'fileSizeBytes': fileSizeBytes,
  };

  static StoredRecording? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final audioPath = value['audioPath'] ?? value['uri'];
    final startedAt = value['startedAt'];
    final duration = value['durationSeconds'];
    final fileSize = value['fileSizeBytes'];
    if (id is! String ||
        id.isEmpty ||
        audioPath is! String ||
        audioPath.isEmpty ||
        startedAt is! String ||
        duration is! num ||
        !duration.isFinite ||
        duration < 0) {
      return null;
    }

    final parsedDate = DateTime.tryParse(startedAt);
    if (parsedDate == null) return null;

    final rawEvents = value['soundEvents'];
    final events = rawEvents is List
        ? rawEvents
              .map(SoundEvent.tryFromJson)
              .whereType<SoundEvent>()
              .toList(growable: false)
        : const <SoundEvent>[];

    return StoredRecording(
      id: id,
      audioPath: audioPath,
      startedAt: parsedDate,
      durationSeconds: duration.toDouble(),
      soundEvents: events,
      fileSizeBytes: fileSize is int && fileSize >= 0 ? fileSize : 0,
    );
  }
}
