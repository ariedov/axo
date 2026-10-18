import 'dart:convert';

import '../config.dart';
import 'models.dart';
import 'today.dart';

class DayHistory {
  const DayHistory({
    this.activatedOn,
    this.days = const {},
    this.bonusDays = const [],
    this.lockedDays = const [],
    this.highlights = const {},
  });

  final String? activatedOn;
  final Map<String, DayProgress> days;

  /// Days an all-done bonus (daily and/or streak) was already awarded.
  final List<String> bonusDays;

  /// Previous days locked by a parent: tasks cannot be marked or verified.
  /// Empty by default (unlocked).
  final List<String> lockedDays;

  /// "Something good that happened" notes, keyed by day stamp.
  final Map<String, String> highlights;

  DayProgress? operator [](String day) => days[day];

  bool bonusOn(String day) => bonusDays.contains(day);

  bool lockedOn(String day) => lockedDays.contains(day);

  String? highlightOn(String day) {
    final note = highlights[day];
    if (note == null || note.isEmpty) return null;
    return note;
  }

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
    Map<String, String>? highlights,
  }) {
    return DayHistory(
      activatedOn: activatedOn ?? this.activatedOn,
      days: days ?? this.days,
      bonusDays: bonusDays ?? this.bonusDays,
      lockedDays: lockedDays ?? this.lockedDays,
      highlights: highlights ?? this.highlights,
    );
  }

  DayHistory withActivatedOn(String day) {
    return DayHistory(
      activatedOn: day,
      days: days,
      bonusDays: bonusDays,
      lockedDays: lockedDays,
      highlights: highlights,
    );
  }

  DayHistory withDay(DayProgress progress) {
    return DayHistory(
      activatedOn: activatedOn,
      days: {...days, progress.day: progress},
      bonusDays: bonusDays,
      lockedDays: lockedDays,
      highlights: highlights,
    );
  }

  DayHistory withBonusDay(String day) {
    return DayHistory(
      activatedOn: activatedOn,
      days: days,
      bonusDays: {...bonusDays, day}.toList()..sort(),
      lockedDays: lockedDays,
      highlights: highlights,
    );
  }

  DayHistory withLockedDay(String day) {
    return DayHistory(
      activatedOn: activatedOn,
      days: days,
      bonusDays: bonusDays,
      lockedDays: {...lockedDays, day}.toList()..sort(),
      highlights: highlights,
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
      highlights: highlights,
    );
  }

  DayHistory withHighlight(String day, String note) {
    final trimmed = cleanDayHighlight(note);
    if (trimmed == null) return withoutHighlight(day);
    if (highlights[day] == trimmed) return this;
    return _withHighlights({...highlights, day: trimmed});
  }

  DayHistory withoutHighlight(String day) {
    if (!highlights.containsKey(day)) return this;
    return _withHighlights({
      for (final entry in highlights.entries)
        if (entry.key != day) entry.key: entry.value,
    });
  }

  DayHistory _withHighlights(Map<String, String> next) {
    final keys = next.keys.toList()..sort();
    return DayHistory(
      activatedOn: activatedOn,
      days: days,
      bonusDays: bonusDays,
      lockedDays: lockedDays,
      highlights: {for (final key in keys) key: next[key]!},
    );
  }

  Map<String, dynamic> toJson() => {
    'activatedOn': activatedOn,
    'days': {for (final entry in days.entries) entry.key: entry.value.toJson()},
    if (bonusDays.isNotEmpty) 'bonusDays': bonusDays,
    if (lockedDays.isNotEmpty) 'lockedDays': lockedDays,
    if (highlights.isNotEmpty)
      'highlights': {
        for (final key in (highlights.keys.toList()..sort()))
          key: highlights[key],
      },
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
      highlights: highlightsFromJson(json['highlights']),
    );
  }
}

String? cleanDayHighlight(String note) {
  final trimmed = note.trim();
  if (trimmed.isEmpty) return null;
  final max = AppConfig.dayHighlightMaxLength;
  if (trimmed.length <= max) return trimmed;
  var end = max;
  final unit = trimmed.codeUnitAt(end - 1);
  if (unit >= 0xD800 && unit <= 0xDBFF && end > 1) end -= 1;
  return trimmed.substring(0, end);
}

Map<String, String> highlightsFromJson(Object? raw) {
  if (raw is! Map) return const {};
  final notes = <String, String>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! String) continue;
    final note = cleanDayHighlight(value);
    if (note == null) continue;
    notes['${entry.key}'] = note;
  }
  if (notes.isEmpty) return const {};
  final keys = notes.keys.toList()..sort();
  return {for (final key in keys) key: notes[key]!};
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
