import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

abstract interface class ForegroundRecordingController {
  Future<void> initialize();
  Future<void> start();
  Future<void> stop();
}

class NoopForegroundRecordingController
    implements ForegroundRecordingController {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class AndroidForegroundRecordingController
    implements ForegroundRecordingController {
  static const _serviceId = 3801;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'snorer_recording',
        channelName: 'Snorer-opname',
        channelDescription:
            'Toont wanneer Snorer een nachtelijke opname maakt.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  @override
  Future<void> start() async {
    await initialize();
    await _requestPermissions();
    if (await FlutterForegroundTask.isRunningService) return;

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'Snorer neemt op',
      notificationText: 'Slaapgeluiden worden lokaal opgeslagen.',
      serviceTypes: const [ForegroundServiceTypes.microphone],
      callback: startForegroundTaskCallback,
    );
    if (result is ServiceRequestFailure) {
      throw StateError(result.error.toString());
    }
  }

  @override
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());
}

class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.sendDataToMain({'action': 'stop'});
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {}
}
