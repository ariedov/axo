import 'dart:convert';

import 'models.dart';
import 'today.dart';

class DayHistory {
  const DayHistory({this.activatedOn, this.days = const {}});

  final String? activatedOn;
  final Map<String, DayProgress> days;

  DayProgress? operator [](String day) => days[day];

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
  }) {
    return DayHistory(
      activatedOn: activatedOn ?? this.activatedOn,
      days: days ?? this.days,
    );
  }

  DayHistory withActivatedOn(String day) {
    return DayHistory(activatedOn: day, days: days);
  }

  DayHistory withDay(DayProgress progress) {
    return DayHistory(
      activatedOn: activatedOn,
      days: {...days, progress.day: progress},
    );
  }

  Map<String, dynamic> toJson() => {
    'activatedOn': activatedOn,
    'days': {
      for (final entry in days.entries) entry.key: entry.value.toJson(),
    },
  };

  factory DayHistory.fromJson(Map<String, dynamic> json) {
    final raw = json['days'] as Map<String, dynamic>? ?? {};
    return DayHistory(
      activatedOn: json['activatedOn'] as String?,
      days: {
        for (final entry in raw.entries)
          entry.key: DayProgress.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          ),
      },
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
