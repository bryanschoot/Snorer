import 'package:flutter/foundation.dart';

import '../../core/recording_size_unit.dart';
import '../../data/services/recording_size_preferences.dart';

class RecordingSizeController extends ChangeNotifier {
  RecordingSizeController({required this._preferences});

  final RecordingSizePreferences _preferences;
  Future<void> _saveQueue = Future<void>.value();
  RecordingSizeUnit _unit = RecordingSizeUnit.megabytes;

  RecordingSizeUnit get unit => _unit;

  Future<void> initialize() async {
    _unit = await _preferences.load();
    notifyListeners();
  }

  Future<void> setUnit(RecordingSizeUnit unit) async {
    if (_unit == unit) return;
    _unit = unit;
    notifyListeners();
    final save = _saveQueue.then((_) => _preferences.save(unit));
    _saveQueue = save.catchError((_) {});
    await save;
  }
}
