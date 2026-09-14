import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../strings.dart';
import 'reminders.dart';

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;
  var _failed = false;
  var _serviceActive = false;

  @override
  bool get canSchedule => !kIsWeb;

  @override
  Future<void> Function(String actionId)? onTimerAction;

  Future<bool> _ensureReady() async {
    if (kIsWeb || _failed) return false;
    if (_ready) return true;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: _handleResponse,
      );
      _ready = ok ?? true;
      return _ready;
    } catch (_) {
      _failed = true;
      return false;
    }
  }

  void _handleResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == null || actionId.isEmpty) return;
    unawaited(onTimerAction?.call(actionId));
  }

  AndroidNotificationDetails _timerAndroidDetails(ScheduledReminder reminder) {
    final label = reminder.actionLabel ?? S.timerMute;
    return AndroidNotificationDetails(
      'axo-timer',
      S.timer,
      channelDescription: S.timerChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      when: reminder.when.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      onlyAlertOnce: true,
      actions: [
        AndroidNotificationAction(
          reminder.actionId ?? timerMuteAction,
          label,
          showsUserInterface: true,
        ),
      ],
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> hasPermission() async {
    if (!await _ensureReady()) return false;
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final status = await ios.checkPermissions();
      return status?.isEnabled ?? false;
    }
    final macOS = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macOS != null) {
      final status = await macOS.checkPermissions();
      return status?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!await _ensureReady()) return false;
    final android = _android;
    if (android != null) {
      final notifications =
          await android.requestNotificationsPermission() ?? false;
      await android.requestExactAlarmsPermission();
      return notifications;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final macOS = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macOS != null) {
      return await macOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  @override
  Future<void> ensureTimerService(ScheduledReminder reminder) async {
    if (!canSchedule) return;
    if (_serviceActive) return;
    if (!await _ensureReady()) return;
    final android = _android;
    if (android == null) return;
    try {
      await android.startForegroundService(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        notificationDetails: _timerAndroidDetails(reminder),
        foregroundServiceTypes: const {
          AndroidServiceForegroundType.foregroundServiceTypeMediaPlayback,
        },
      );
      _serviceActive = true;
    } catch (_) {
      // Starting from the background is restricted; the pinned
      // notification from showOngoing still covers the timer.
    }
  }

  @override
  Future<void> stopTimerService() async {
    if (!_serviceActive) return;
    _serviceActive = false;
    try {
      await _android?.stopForegroundService();
    } catch (_) {
      // Nothing to stop.
    }
  }

  @override
  Future<void> showOngoing(ScheduledReminder reminder) async {
    if (!await _ensureReady()) return;
    const darwin = DarwinNotificationDetails(
      presentAlert: false,
      presentSound: false,
      presentBanner: false,
      presentList: true,
    );
    final details = NotificationDetails(
      android: _timerAndroidDetails(reminder),
      iOS: darwin,
      macOS: darwin,
    );
    try {
      await _plugin.show(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        notificationDetails: details,
      );
    } catch (_) {
      // Notification UI is unavailable; skip silently.
    }
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async {
    if (!await _ensureReady()) return;
    final when = tz.TZDateTime.from(reminder.when, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'axo-reminders',
        S.reminders,
        channelDescription: S.remindersChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!await _ensureReady()) return;
    await _plugin.cancel(id: id);
  }
}
