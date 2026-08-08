import 'package:flutter/foundation.dart';

import '../../data/services/app_update_service.dart';

enum UpdateCheckStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  failed,
}

class UpdateController extends ChangeNotifier {
  UpdateController({
    required this.currentVersion,
    required this.service,
  });

  final String currentVersion;
  final AppUpdateService service;

  UpdateCheckStatus _status = UpdateCheckStatus.idle;
  AppRelease? _availableRelease;
  Object? _error;

  UpdateCheckStatus get status => _status;
  AppRelease? get availableRelease => _availableRelease;
  Object? get error => _error;

  Future<void> checkForUpdate() async {
    if (_status == UpdateCheckStatus.checking) return;

    _status = UpdateCheckStatus.checking;
    _error = null;
    notifyListeners();
    try {
      _availableRelease = await service.checkForUpdate(currentVersion);
      _status = _availableRelease == null
          ? UpdateCheckStatus.upToDate
          : UpdateCheckStatus.updateAvailable;
    } catch (error) {
      _availableRelease = null;
      _error = error;
      _status = UpdateCheckStatus.failed;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}
