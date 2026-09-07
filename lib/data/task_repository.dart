import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';
import 'today.dart';

class TaskSnapshot {
  const TaskSnapshot({required this.day, required this.tasks});

  final String day;
  final List<HabitTask> tasks;

  Map<String, dynamic> toJson() => {
    'day': day,
    'tasks': tasks.map((task) => task.toJson()).toList(),
  };

  factory TaskSnapshot.fromJson(Map<String, dynamic> json) {
    return TaskSnapshot(
      day: json['day'] as String,
      tasks: (json['tasks'] as List)
          .map((item) => HabitTask.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

List<HabitTask> pendingRecurring(List<HabitTask> tasks) {
  return [
    for (final task in tasks)
      if (!task.todayOnly) task.copyWith(status: TaskStatus.pending),
  ];
}

TodayLoad advanceToToday(Map<String, TaskSnapshot> days, String today) {
  if (days.containsKey(today)) {
    return TodayLoad(current: days[today]!, days: days);
  }

  final latest = days.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  final previous = days[latest]!;
  if (latest.compareTo(today) > 0) {
    final rolled = TaskSnapshot(
      day: today,
      tasks: pendingRecurring(previous.tasks),
    );
    days[today] = rolled;
    return TodayLoad(current: rolled, days: days);
  }

  final template = pendingRecurring(previous.tasks);
  var cursor = dateFromStamp(latest);
  final end = dateFromStamp(today);
  cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  while (!cursor.isAfter(end)) {
    final stamp = stampFromDate(cursor);
    days[stamp] = TaskSnapshot(day: stamp, tasks: template);
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }
  return TodayLoad(current: days[today]!, previous: previous, days: days);
}

Map<String, TaskSnapshot> taskDaysFromJson(Map<String, dynamic> json) {
  return {
    for (final entry in json.entries)
      entry.key: TaskSnapshot.fromJson(entry.value as Map<String, dynamic>),
  };
}

Map<String, dynamic> taskDaysToJson(Map<String, TaskSnapshot> days) {
  return {for (final entry in days.entries) entry.key: entry.value.toJson()};
}

abstract class TaskRepository {
  Future<TodayLoad> loadToday();
  Future<void> save(TaskSnapshot snapshot);
  Future<TaskSnapshot?> loadDay(String day);
  Future<void> replaceAll(Map<String, TaskSnapshot> days);
}

class TodayLoad {
  const TodayLoad({required this.current, this.previous, this.days = const {}});

  final TaskSnapshot current;
  final TaskSnapshot? previous;
  final Map<String, TaskSnapshot> days;
}

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(this._read, this._write, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const daysKey = 'task_days';
  static const legacyKey = 'tasks_snapshot';
  static const _seedAsset = 'assets/data/tasks.json';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;
  final DateTime Function() _now;

  @override
  Future<TodayLoad> loadToday() async {
    final today = todayStamp(_now());
    var days = await _readDays();
    if (days.isEmpty) {
      final seeded = TaskSnapshot(day: today, tasks: await _seed());
      days = {today: seeded};
      await _writeDays(days);
      return TodayLoad(current: seeded, days: days);
    }

    final hadToday = days.containsKey(today);
    final loaded = advanceToToday(days, today);
    if (!hadToday) await _writeDays(loaded.days);
    return loaded;
  }

  @override
  Future<void> save(TaskSnapshot snapshot) async {
    final days = await _readDays();
    days[snapshot.day] = snapshot;
    await _writeDays(days);
  }

  @override
  Future<TaskSnapshot?> loadDay(String day) async {
    final days = await _readDays();
    return days[day];
  }

  @override
  Future<void> replaceAll(Map<String, TaskSnapshot> days) {
    return _writeDays(Map.of(days));
  }

  Future<Map<String, TaskSnapshot>> _readDays() async {
    final raw = await _read(daysKey);
    if (raw != null) {
      return taskDaysFromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    final legacy = await _read(legacyKey);
    if (legacy == null) return {};
    final saved = TaskSnapshot.fromJson(
      jsonDecode(legacy) as Map<String, dynamic>,
    );
    final days = {saved.day: saved};
    await _writeDays(days);
    return days;
  }

  Future<void> _writeDays(Map<String, TaskSnapshot> days) {
    return _write(daysKey, jsonEncode(taskDaysToJson(days)));
  }

  Future<List<HabitTask>> _seed() async {
    final raw = await rootBundle.loadString(_seedAsset);
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list) HabitTask.fromJson(item as Map<String, dynamic>),
    ];
  }
}

class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository(
    TaskSnapshot snapshot, {
    Map<String, TaskSnapshot>? days,
    DateTime Function()? now,
  }) : days = {...?days, snapshot.day: snapshot},
       currentDay = snapshot.day,
       _now = now ?? DateTime.now;

  String currentDay;
  Map<String, TaskSnapshot> days;
  final DateTime Function() _now;

  @override
  Future<TodayLoad> loadToday() async {
    final today = todayStamp(_now());
    if (days.isEmpty) {
      final empty = TaskSnapshot(day: today, tasks: const []);
      days[today] = empty;
      currentDay = today;
      return TodayLoad(current: empty, days: days);
    }
    final loaded = advanceToToday(days, today);
    days = loaded.days;
    currentDay = today;
    return loaded;
  }

  @override
  Future<void> save(TaskSnapshot snapshot) async {
    days[snapshot.day] = snapshot;
  }

  @override
  Future<TaskSnapshot?> loadDay(String day) async => days[day];

  @override
  Future<void> replaceAll(Map<String, TaskSnapshot> all) async {
    days = Map.of(all);
    if (all.isEmpty) return;
    currentDay = all.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  }
}
