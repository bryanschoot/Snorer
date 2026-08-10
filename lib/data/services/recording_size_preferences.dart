import 'package:shared_preferences/shared_preferences.dart';

import '../../core/recording_size_unit.dart';

abstract interface class RecordingSizePreferences {
  Future<RecordingSizeUnit> load();
  Future<void> save(RecordingSizeUnit unit);
}

class LocalRecordingSizePreferences implements RecordingSizePreferences {
  static const _storageKey = '@snorer/recording-size-unit/v1';

  @override
  Future<RecordingSizeUnit> load() async {
    final preferences = await SharedPreferences.getInstance();
    return RecordingSizeUnit.fromStorage(preferences.getString(_storageKey));
  }

  @override
  Future<void> save(RecordingSizeUnit unit) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, unit.name);
  }
}
