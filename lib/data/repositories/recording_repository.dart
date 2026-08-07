import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/recording.dart';

const recordingsStorageKey = '@snorer/recordings/v1';

abstract interface class RecordingRepository {
  Future<List<StoredRecording>> loadRecordings();
  Future<void> saveRecordings(List<StoredRecording> recordings);
  Future<String> createAudioPath(DateTime startedAt);
  Future<void> deleteAudioFile(String path);
}

class LocalRecordingRepository implements RecordingRepository {
  @override
  Future<List<StoredRecording>> loadRecordings() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(recordingsStorageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final recordings = decoded
          .map(StoredRecording.tryFromJson)
          .whereType<StoredRecording>()
          .where((recording) => File(recording.audioPath).existsSync())
          .toList(growable: false);
      return recordings;
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> saveRecordings(List<StoredRecording> recordings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      recordingsStorageKey,
      jsonEncode(recordings.map((recording) => recording.toJson()).toList()),
    );
  }

  @override
  Future<String> createAudioPath(DateTime startedAt) async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDirectory = Directory('${directory.path}/recordings');
    await recordingsDirectory.create(recursive: true);
    final stamp = startedAt.toUtc().millisecondsSinceEpoch;
    return '${recordingsDirectory.path}/snorer-$stamp.wav';
  }

  @override
  Future<void> deleteAudioFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
