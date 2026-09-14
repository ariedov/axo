import 'timer_repository.dart';

abstract final class ReminderId {
  /// Shown as a persistent notification while the timer runs; on Android it
  /// is the foreground-service notification. The one-off "done" alarm
  /// replaces it (same id) so nothing lingers afterwards.
  static const timer = 1;
  static const eveningLeftovers = 2;
}

/// Notification action id that toggles timer music.
const timerMuteAction = 'timer-mute';

/// Extra delay before the timer-done alarm so an in-app completion can
/// cancel it first instead of flashing a duplicate notification.
const timerDoneBuffer = Duration(seconds: 3);

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    this.actionId,
    this.actionLabel,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;

  /// Optional notification action button.
  final String? actionId;
  final String? actionLabel;
}

abstract class ReminderScheduler {
  bool get canSchedule => true;

  /// Invoked on the main isolate when the user taps a notification action.
  Future<void> Function(String actionId)? onTimerAction;

  Future<bool> hasPermission();
  Future<bool> requestPermission();

  /// Android only: keeps the app process alive while the timer runs
  /// (media playback foreground service). No-op elsewhere.
  Future<void> ensureTimerService(ScheduledReminder reminder);
  Future<void> stopTimerService();
  Future<void> showOngoing(ScheduledReminder reminder);
  Future<void> schedule(ScheduledReminder reminder);
  Future<void> cancel(int id);
}

class NoopReminderScheduler implements ReminderScheduler {
  NoopReminderScheduler();

  @override
  bool get canSchedule => true;

  @override
  Future<void> Function(String actionId)? onTimerAction;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> ensureTimerService(ScheduledReminder reminder) async {}

  @override
  Future<void> stopTimerService() async {}

  @override
  Future<void> showOngoing(ScheduledReminder reminder) async {}

  @override
  Future<void> schedule(ScheduledReminder reminder) async {}

  @override
  Future<void> cancel(int id) async {}
}

class InMemoryReminderScheduler implements ReminderScheduler {
  InMemoryReminderScheduler({this.permissionGranted = true});

  @override
  bool get canSchedule => true;

  @override
  Future<void> Function(String actionId)? onTimerAction;

  bool permissionGranted;
  var requestCount = 0;
  var serviceStarts = 0;
  var serviceStops = 0;
  var _serviceActive = false;
  final scheduled = <int, ScheduledReminder>{};
  final shown = <ScheduledReminder>[];

  Future<void> fire(String actionId) async {
    final callback = onTimerAction;
    if (callback == null) return;
    await callback(actionId);
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    return permissionGranted;
  }

  @override
  Future<void> ensureTimerService(ScheduledReminder reminder) async {
    if (_serviceActive) return;
    serviceStarts++;
    _serviceActive = true;
    scheduled[reminder.id] = reminder;
  }

  @override
  Future<void> stopTimerService() async {
    if (!_serviceActive) return;
    _serviceActive = false;
    serviceStops++;
  }

  @override
  Future<void> showOngoing(ScheduledReminder reminder) async {
    shown.add(reminder);
    scheduled[reminder.id] = reminder;
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async {
    scheduled[reminder.id] = reminder;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }
}

DateTime? nextEveningAt({
  required DateTime now,
  required int hour,
  required int minute,
  required bool enabled,
  required bool hasLeftovers,
}) {
  if (!enabled || !hasLeftovers) return null;
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (now.isBefore(today)) return today;
  return DateTime(now.year, now.month, now.day + 1, hour, minute);
}

DateTime? timerDoneAt({required DateTime now, required TimerSession? active}) {
  if (active == null || !active.isRunning) return null;
  final remaining = active.targetMillis - active.elapsedMillisAt(now);
  if (remaining <= 0) return null;
  return now.add(Duration(milliseconds: remaining));
}
