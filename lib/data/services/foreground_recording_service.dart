import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../core/localization/snorer_language.dart';
import '../../core/localization/app_localizations.dart';

const _notificationIconMetadataName =
    'com.bryanschoot.snorer.NOTIFICATION_ICON';

NotificationIcon buildSnorerNotificationIcon(Color accent) => NotificationIcon(
  metaDataName: _notificationIconMetadataName,
  backgroundColor: accent,
);

abstract interface class ForegroundRecordingController {
  Future<void> initialize();
  void setLanguage(SnorerLanguage language);
  void setNotificationAccent(Color color);
  Future<void> start();
  Future<void> stop();
}

class NoopForegroundRecordingController
    implements ForegroundRecordingController {
  @override
  Future<void> initialize() async {}

  @override
  void setLanguage(SnorerLanguage language) {}

  @override
  void setNotificationAccent(Color color) {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class AndroidForegroundRecordingController
    implements ForegroundRecordingController {
  static const _serviceId = 3801;
  bool _initialized = false;
  SnorerLanguage _language = SnorerLanguage.dutch;
  Color _notificationAccent = const Color(0xFF5ED0C0);

  @override
  void setLanguage(SnorerLanguage language) {
    _language = language;
  }

  @override
  void setNotificationAccent(Color color) {
    if (_notificationAccent == color) return;
    _notificationAccent = color;
    if (_initialized) unawaited(_updateNotificationIcon());
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final strings = lookupAppLocalizations(_language.locale);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'snorer_recording',
        channelName: strings.notificationChannelName,
        channelDescription: strings.notificationChannelDescription,
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

  NotificationIcon get _notificationIcon =>
      buildSnorerNotificationIcon(_notificationAccent);

  Future<void> _updateNotificationIcon() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationIcon: _notificationIcon,
        );
      }
    } catch (_) {}
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

    final strings = lookupAppLocalizations(_language.locale);
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: strings.notificationTitle,
      notificationText: strings.notificationText,
      notificationIcon: _notificationIcon,
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
