import 'dart:convert';

import '../config.dart';
import 'day_history_repository.dart';
import 'game_plays.dart';
import 'models.dart';
import 'task_repository.dart';
import 'timer_repository.dart';
import 'today.dart';

class BackupSnapshot {
  const BackupSnapshot({
    required this.exportedAt,
    required this.points,
    required this.onboardingComplete,
    required this.tasks,
    required this.goals,
    required this.history,
    required this.plays,
    this.taskDays = const {},
    this.strikes = 0,
    this.strikeDay,
    this.penaltyPoints = AppConfig.defaultPenaltyPoints,
    this.gameLimitEnabled = AppConfig.defaultGameLimitEnabled,
    this.rewardedPlays = AppConfig.rewardedPlays,
    this.playLimitMinutes = AppConfig.playLimitMinutes,
    this.completionBonusEnabled = AppConfig.defaultCompletionBonusEnabled,
    this.completionBonusPoints = AppConfig.defaultCompletionBonusPoints,
    this.timer = const TimerSnapshot(),
  });

  static const appId = 'axo';
  static const format = 2;

  final DateTime exportedAt;
  final int points;
  final bool onboardingComplete;
  final TaskSnapshot tasks;
  final Map<String, TaskSnapshot> taskDays;
  final List<RewardGoal> goals;
  final DayHistory history;
  final GamePlaysSnapshot plays;
  final int strikes;
  final String? strikeDay;
  final int penaltyPoints;
  final bool gameLimitEnabled;
  final int rewardedPlays;
  final int playLimitMinutes;
  final bool completionBonusEnabled;
  final int completionBonusPoints;
  final TimerSnapshot timer;

  String get fileName => 'axo-${todayStamp(exportedAt)}.json';

  Map<String, TaskSnapshot> get allTaskDays {
    if (taskDays.isNotEmpty) return taskDays;
    return {tasks.day: tasks};
  }

  Map<String, dynamic> toJson() => {
    'app': appId,
    'format': format,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'data': {
      'points': points,
      'onboardingComplete': onboardingComplete,
      'tasks': tasks.toJson(),
      'taskDays': taskDaysToJson(allTaskDays),
      'goals': [for (final goal in goals) goal.toJson()],
      'history': history.toJson(),
      'gamePlays': plays.toJson(),
      'strikes': strikes,
      'strikeDay': strikeDay,
      'penaltyPoints': penaltyPoints,
      'gameLimitEnabled': gameLimitEnabled,
      'rewardedPlays': rewardedPlays,
      'playLimitMinutes': playLimitMinutes,
      'completionBonusEnabled': completionBonusEnabled,
      'completionBonusPoints': completionBonusPoints,
      'timer': timer.toJson(),
    },
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['app'] != appId) {
      throw const FormatException('not an Axo backup');
    }
    final format = json['format'] as int? ?? 0;
    if (format < 1) {
      throw const FormatException('unknown backup format');
    }
    if (format > BackupSnapshot.format) {
      throw const FormatException('backup is from a newer app version');
    }
    final data = json['data'] as Map<String, dynamic>;
    final tasks = TaskSnapshot.fromJson(data['tasks'] as Map<String, dynamic>);
    final rawDays = data['taskDays'] as Map<String, dynamic>?;
    return BackupSnapshot(
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      points: (data['points'] as num).toInt(),
      onboardingComplete: data['onboardingComplete'] == true,
      tasks: tasks,
      taskDays: rawDays == null || rawDays.isEmpty
          ? {tasks.day: tasks}
          : taskDaysFromJson(rawDays),
      goals: [
        for (final item in data['goals'] as List)
          RewardGoal.fromJson(item as Map<String, dynamic>),
      ],
      history: DayHistory.fromJson(data['history'] as Map<String, dynamic>),
      plays: GamePlaysSnapshot.fromJson(
        data['gamePlays'] as Map<String, dynamic>,
      ),
      strikes: (data['strikes'] as num?)?.toInt() ?? 0,
      strikeDay: data['strikeDay'] as String?,
      penaltyPoints:
          (data['penaltyPoints'] as num?)?.toInt() ??
          AppConfig.defaultPenaltyPoints,
      gameLimitEnabled:
          data['gameLimitEnabled'] as bool? ??
          AppConfig.defaultGameLimitEnabled,
      rewardedPlays:
          (data['rewardedPlays'] as num?)?.toInt() ?? AppConfig.rewardedPlays,
      playLimitMinutes:
          (data['playLimitMinutes'] as num?)?.toInt() ??
          AppConfig.playLimitMinutes,
      completionBonusEnabled:
          data['completionBonusEnabled'] as bool? ??
          AppConfig.defaultCompletionBonusEnabled,
      completionBonusPoints:
          (data['completionBonusPoints'] as num?)?.toInt() ??
          AppConfig.defaultCompletionBonusPoints,
      timer: data['timer'] is Map<String, dynamic>
          ? TimerSnapshot.fromJson(data['timer'] as Map<String, dynamic>)
          : const TimerSnapshot(),
    );
  }
}
