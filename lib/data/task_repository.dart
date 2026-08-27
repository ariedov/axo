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

abstract class TaskRepository {
  Future<TodayLoad> loadToday();
  Future<void> save(TaskSnapshot snapshot);
}

class TodayLoad {
  const TodayLoad({required this.current, this.previous});

  final TaskSnapshot current;
  final TaskSnapshot? previous;
}

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(
    this._read,
    this._write, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _key = 'tasks_snapshot';
  static const _seedAsset = 'assets/data/tasks.json';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;
  final DateTime Function() _now;

  @override
  Future<TodayLoad> loadToday() async {
    final today = todayStamp(_now());
    final raw = await _read(_key);
    if (raw == null) {
      final seeded = TaskSnapshot(day: today, tasks: await _seed());
      await save(seeded);
      return TodayLoad(current: seeded);
    }

    final saved = TaskSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (saved.day == today) return TodayLoad(current: saved);

    final rolled = TaskSnapshot(
      day: today,
      tasks: [
        for (final task in saved.tasks)
          if (!task.todayOnly) task.copyWith(status: TaskStatus.pending),
      ],
    );
    await save(rolled);
    return TodayLoad(current: rolled, previous: saved);
  }

  @override
  Future<void> save(TaskSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
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
  InMemoryTaskRepository(this.snapshot);

  TaskSnapshot snapshot;

  @override
  Future<TodayLoad> loadToday() async => TodayLoad(current: snapshot);

  @override
  Future<void> save(TaskSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
