import 'dart:convert';

import 'models.dart';
import 'today.dart';

class DayHistory {
  const DayHistory({
    this.activatedOn,
    this.days = const {},
    this.bonusDays = const [],
    this.lockedDays = const [],
  });

  final String? activatedOn;
  final Map<String, DayProgress> days;

  /// Days an all-done bonus (daily and/or streak) was already awarded.
  final List<String> bonusDays;

  /// Previous days locked by a parent: tasks cannot be marked or verified.
  /// Empty by default (unlocked).
  final List<String> lockedDays;

  DayProgress? operator [](String day) => days[day];

  bool bonusOn(String day) => bonusDays.contains(day);

  bool lockedOn(String day) => lockedDays.contains(day);

  int currentStreak(String today) {
    var day = this[today]?.isFull == true ? today : previousStamp(today);
    var streak = 0;
    while (this[day]?.isFull == true) {
      streak += 1;
      day = previousStamp(day);
    }
    return streak;
  }

  DayHistory copyWith({
    String? activatedOn,
    Map<String, DayProgress>? days,
    List<String>? bonusDays,
    List<String>? lockedDays,
  }) {
    return DayHistory(
      activatedOn: activatedOn ?? this.activatedOn,
      days: days ?? this.days,
      bonusDays: bonusDays ?? this.bonusDays,
      lockedDays: lockedDays ?? this.lockedDays,
    );
  }

  DayHistory withActivatedOn(String day) {
    return DayHistory(
      activatedOn: day,
      days: days,
      bonusDays: bonusDays,
      lockedDays: lockedDays,
    );
  }

  DayHistory withDay(DayProgress progress) {
    return DayHistory(
      activatedOn: activatedOn,
      days: {...days, progress.day: progress},
      bonusDays: bonusDays,
      lockedDays: lockedDays,
    );
  }

  DayHistory withBonusDay(String day) {
    return DayHistory(
      activatedOn: activatedOn,
      days: days,
      bonusDays: {...bonusDays, day}.toList()..sort(),
      lockedDays: lockedDays,
    );
  }

  DayHistory withLockedDay(String day) {
    return DayHistory(
      activatedOn: activatedOn,
      days: days,
      bonusDays: bonusDays,
      lockedDays: {...lockedDays, day}.toList()..sort(),
    );
  }

  DayHistory withUnlockedDay(String day) {
    return DayHistory(
      activatedOn: activatedOn,
      days: days,
      bonusDays: bonusDays,
      lockedDays: [
        for (final item in lockedDays)
          if (item != day) item,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'activatedOn': activatedOn,
    'days': {for (final entry in days.entries) entry.key: entry.value.toJson()},
    if (bonusDays.isNotEmpty) 'bonusDays': bonusDays,
    if (lockedDays.isNotEmpty) 'lockedDays': lockedDays,
  };

  factory DayHistory.fromJson(Map<String, dynamic> json) {
    final raw = json['days'] as Map<String, dynamic>? ?? {};
    final rawBonus = json['bonusDays'] as List?;
    final rawLocked = json['lockedDays'] as List?;
    return DayHistory(
      activatedOn: json['activatedOn'] as String?,
      days: {
        for (final entry in raw.entries)
          entry.key: DayProgress.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          ),
      },
      bonusDays: [for (final day in rawBonus ?? const []) day as String],
      lockedDays: [for (final day in rawLocked ?? const []) day as String],
    );
  }
}

abstract class DayHistoryRepository {
  Future<DayHistory> load();
  Future<void> save(DayHistory history);
}

class LocalDayHistoryRepository implements DayHistoryRepository {
  LocalDayHistoryRepository(this._read, this._write);

  static const _key = 'day_history';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<DayHistory> load() async {
    final raw = await _read(_key);
    if (raw == null) return const DayHistory();
    return DayHistory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(DayHistory history) {
    return _write(_key, jsonEncode(history.toJson()));
  }
}

class InMemoryDayHistoryRepository implements DayHistoryRepository {
  InMemoryDayHistoryRepository([DayHistory? history])
    : history = history ?? const DayHistory();

  DayHistory history;

  @override
  Future<DayHistory> load() async => history;

  @override
  Future<void> save(DayHistory history) async {
    this.history = history;
  }
}
