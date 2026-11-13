import 'dart:convert';

import '../config.dart';

class ReminderSettingsSnapshot {
  const ReminderSettingsSnapshot({
    this.enabled = AppConfig.defaultEveningReminderEnabled,
    this.hour = AppConfig.defaultEveningReminderHour,
    this.minute = AppConfig.defaultEveningReminderMinute,
    this.moodNudgesEnabled = AppConfig.defaultMoodNudgesEnabled,
    this.missesYouEnabled = AppConfig.defaultMissesYouEnabled,
    this.lastProudDay,
    this.lastMissesDay,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final bool moodNudgesEnabled;
  final bool missesYouEnabled;
  final String? lastProudDay;
  final String? lastMissesDay;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'moodNudgesEnabled': moodNudgesEnabled,
    'missesYouEnabled': missesYouEnabled,
    'lastProudDay': lastProudDay,
    'lastMissesDay': lastMissesDay,
  };

  factory ReminderSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    final hour =
        (json['hour'] as num?)?.toInt() ?? AppConfig.defaultEveningReminderHour;
    final minute =
        (json['minute'] as num?)?.toInt() ??
        AppConfig.defaultEveningReminderMinute;
    return ReminderSettingsSnapshot(
      enabled:
          json['enabled'] as bool? ?? AppConfig.defaultEveningReminderEnabled,
      hour: hour < 0 || hour > 23 ? AppConfig.defaultEveningReminderHour : hour,
      minute: minute < 0 || minute > 59
          ? AppConfig.defaultEveningReminderMinute
          : minute,
      moodNudgesEnabled:
          json['moodNudgesEnabled'] as bool? ??
          AppConfig.defaultMoodNudgesEnabled,
      missesYouEnabled:
          json['missesYouEnabled'] as bool? ??
          AppConfig.defaultMissesYouEnabled,
      lastProudDay: json['lastProudDay'] as String?,
      lastMissesDay: json['lastMissesDay'] as String?,
    );
  }
}

abstract class ReminderSettingsRepository {
  Future<ReminderSettingsSnapshot> load();
  Future<void> save(ReminderSettingsSnapshot snapshot);
}

class LocalReminderSettingsRepository implements ReminderSettingsRepository {
  LocalReminderSettingsRepository(this._read, this._write);

  static const _key = 'reminders';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<ReminderSettingsSnapshot> load() async {
    final raw = await _read(_key);
    if (raw == null) return const ReminderSettingsSnapshot();
    return ReminderSettingsSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(ReminderSettingsSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryReminderSettingsRepository implements ReminderSettingsRepository {
  InMemoryReminderSettingsRepository([
    this.snapshot = const ReminderSettingsSnapshot(),
  ]);

  ReminderSettingsSnapshot snapshot;

  @override
  Future<ReminderSettingsSnapshot> load() async => snapshot;

  @override
  Future<void> save(ReminderSettingsSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
