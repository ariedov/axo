import 'dart:convert';

import 'models.dart';

abstract class GoalRepository {
  Future<List<RewardGoal>> load();
  Future<void> save(List<RewardGoal> goals);
}

class LocalGoalRepository implements GoalRepository {
  LocalGoalRepository(this._read, this._write);

  static const _key = 'goals';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<List<RewardGoal>> load() async {
    final raw = await _read(_key);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        RewardGoal.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<RewardGoal> goals) {
    return _write(
      _key,
      jsonEncode([for (final goal in goals) goal.toJson()]),
    );
  }
}

class InMemoryGoalRepository implements GoalRepository {
  InMemoryGoalRepository([List<RewardGoal>? goals]) : goals = goals ?? const [];

  List<RewardGoal> goals;

  @override
  Future<List<RewardGoal>> load() async => goals;

  @override
  Future<void> save(List<RewardGoal> goals) async {
    this.goals = goals;
  }
}
