import 'package:flutter/foundation.dart';

import '../../data/services/app_update_service.dart';

enum UpdateCheckStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  installing,
  installStarted,
  installPermissionRequired,
  installFailed,
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
  Future<void> installUpdate() async {
    final release = _availableRelease;
    if (release == null || _status == UpdateCheckStatus.installing) return;

    _status = UpdateCheckStatus.installing;
    _error = null;
    notifyListeners();
    try {
      final result = await service.install(release);
      _status = result == ApkInstallResult.permissionRequired
          ? UpdateCheckStatus.installPermissionRequired
          : UpdateCheckStatus.installStarted;
    } catch (error) {
      _error = error;
      _status = UpdateCheckStatus.installFailed;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}
