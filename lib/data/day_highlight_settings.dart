import 'dart:convert';

import '../config.dart';

class DayHighlightSettingsSnapshot {
  const DayHighlightSettingsSnapshot({
    this.enabled = AppConfig.defaultDayHighlightEnabled,
  });

  final bool enabled;

  Map<String, dynamic> toJson() => {'enabled': enabled};

  factory DayHighlightSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    return DayHighlightSettingsSnapshot(
      enabled: json['enabled'] as bool? ?? AppConfig.defaultDayHighlightEnabled,
    );
  }
}

abstract class DayHighlightSettingsRepository {
  Future<DayHighlightSettingsSnapshot> load();
  Future<void> save(DayHighlightSettingsSnapshot snapshot);
}

class LocalDayHighlightSettingsRepository
    implements DayHighlightSettingsRepository {
  LocalDayHighlightSettingsRepository(this._read, this._write);

  static const _key = 'day_highlight_settings';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<DayHighlightSettingsSnapshot> load() async {
    final raw = await _read(_key);
    if (raw == null) return const DayHighlightSettingsSnapshot();
    return DayHighlightSettingsSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(DayHighlightSettingsSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryDayHighlightSettingsRepository
    implements DayHighlightSettingsRepository {
  InMemoryDayHighlightSettingsRepository([
    this.snapshot = const DayHighlightSettingsSnapshot(),
  ]);

  DayHighlightSettingsSnapshot snapshot;

  @override
  Future<DayHighlightSettingsSnapshot> load() async => snapshot;

  @override
  Future<void> save(DayHighlightSettingsSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
