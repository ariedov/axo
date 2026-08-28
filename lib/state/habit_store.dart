import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/day_history_repository.dart';
import '../data/game_plays.dart';
import '../data/goal_repository.dart';
import '../data/models.dart';
import '../data/onboarding_flags.dart';
import '../data/parent_auth.dart';
import '../data/points_repository.dart';
import '../data/task_repository.dart';
import '../data/today.dart';

class HabitStore extends ChangeNotifier {
  HabitStore({
    required this.pointsRepo,
    required this.taskRepo,
    required this.parentAuth,
    required this.gamePlays,
    required this.goalRepo,
    required this.historyRepo,
    OnboardingFlags? onboardingFlags,
    this.celebrateFor = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : onboardingFlags = onboardingFlags ?? InMemoryOnboardingFlags(),
       now = now ?? DateTime.now;

  final PointsRepository pointsRepo;
  final TaskRepository taskRepo;
  final ParentAuth parentAuth;
  final GamePlaysRepository gamePlays;
  final GoalRepository goalRepo;
  final DayHistoryRepository historyRepo;
  final OnboardingFlags onboardingFlags;
  final Duration celebrateFor;
  final DateTime Function() now;

  int totalPoints = 0;
  List<HabitTask> tasks = const [];
  List<RewardGoal> goals = const [];
  bool ready = false;
  bool celebrating = false;
  String? parentPassword;
  bool onboardingComplete = false;
  GamePlaysSnapshot plays = GamePlaysSnapshot.empty();
  DayHistory history = const DayHistory();

  bool get needsOnboarding => !onboardingComplete;

  bool checkPassword(String value) => value.trim() == parentPassword;

  int get pendingCount => tasks.where((task) => task.isPending).length;
  int get waitingCount => tasks.where((task) => task.isSubmitted).length;
  int get verifiedCount => tasks.where((task) => task.isVerified).length;
  List<HabitTask> get dailyTasks => [
    for (final task in tasks)
      if (!task.todayOnly) task,
  ];

  Future<void> load() async {
    totalPoints = await pointsRepo.fetchTotal();
    final todayLoad = await taskRepo.loadToday();
    tasks = todayLoad.current.tasks;
    goals = await goalRepo.load();
    parentPassword = await parentAuth.read();
    onboardingComplete = await onboardingFlags.isComplete();
    if (!onboardingComplete &&
        parentPassword != null &&
        parentPassword!.isNotEmpty) {
      onboardingComplete = true;
      await onboardingFlags.markComplete();
    }
    plays = await gamePlays.loadToday();
    history = await historyRepo.load();
    if (todayLoad.previous != null) {
      await _recordSnapshot(todayLoad.previous!);
    }
    await _ensureActivated();
    await _syncTodayHistory();
    ready = true;
    notifyListeners();
  }

  Future<void> setParentPassword(String value) async {
    parentPassword = value.trim();
    await parentAuth.write(parentPassword!);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String password,
    required int startingPoints,
    RewardGoal? goal,
  }) async {
    totalPoints = await pointsRepo.setTotal(startingPoints);
    parentPassword = password.trim();
    await parentAuth.write(parentPassword!);
    if (goal != null) {
      goals = [...goals, goal];
      await _persistGoals();
    }
    onboardingComplete = true;
    await onboardingFlags.markComplete();
    await _ensureActivated();
    await _syncTodayHistory();
    notifyListeners();
  }

  Future<int> adjustPoints(int delta) async {
    if (delta == 0) return 0;
    final next = totalPoints + delta;
    final clamped = next < 0 ? 0 : next;
    final applied = clamped - totalPoints;
    if (applied == 0) return 0;
    totalPoints = await pointsRepo.setTotal(clamped);
    notifyListeners();
    return applied;
  }

  Future<bool> changePassword({
    required String current,
    required String next,
  }) async {
    if (!checkPassword(current)) return false;
    await setParentPassword(next);
    return true;
  }

  int playsUsed(String gameId) => plays.used(gameId);

  int playsLeft(String gameId) {
    final left = AppConfig.rewardedPlaysPerGame - playsUsed(gameId);
    return left < 0 ? 0 : left;
  }

  /// Awards once per completed round. Returns 0 when the daily cap is reached.
  Future<int> tryAwardGamePlay(String gameId, {int? points}) async {
    if (playsLeft(gameId) <= 0) return 0;
    final amount = points ?? AppConfig.gamePlayPoints;

    plays = plays.increment(gameId);
    await gamePlays.save(plays);
    totalPoints = await pointsRepo.award(
      amount: amount,
      taskId: 'game:$gameId',
    );
    notifyListeners();
    return amount;
  }

  Future<void> submit(String taskId) {
    return _update(
      taskId,
      (task) => task.isPending ? task.copyWith(status: TaskStatus.submitted) : task,
    );
  }

  Future<void> unsubmit(String taskId) {
    return _update(
      taskId,
      (task) => task.isSubmitted ? task.copyWith(status: TaskStatus.pending) : task,
    );
  }

  Future<void> verify(String taskId) async {
    final task = tasks.firstWhere((item) => item.id == taskId);
    if (!task.isSubmitted) return;

    totalPoints = await pointsRepo.award(amount: task.points, taskId: task.id);
    celebrating = true;
    await _update(taskId, (item) => item.copyWith(status: TaskStatus.verified));
    if (celebrateFor > Duration.zero) {
      await Future<void>.delayed(celebrateFor);
    }
    celebrating = false;
    notifyListeners();
  }

  Future<void> reject(String taskId) => unsubmit(taskId);

  Future<void> upsertTask(HabitTask task) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks = _insertTask(task);
    } else {
      final copy = [...tasks];
      copy[index] = task;
      tasks = copy;
    }
    await _persist();
    await _syncTodayHistory();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    tasks = [for (final task in tasks) if (task.id != taskId) task];
    await _persist();
    await _syncTodayHistory();
    notifyListeners();
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final copy = [...tasks];
    final task = copy.removeAt(oldIndex);
    copy.insert(newIndex, task);
    tasks = copy;
    await _persist();
    notifyListeners();
  }

  Future<void> reorderDailyTasks(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final daily = dailyTasks;
    final moved = daily.removeAt(oldIndex);
    daily.insert(newIndex, moved);
    var index = 0;
    tasks = [
      for (final task in tasks)
        if (task.todayOnly) task else daily[index++],
    ];
    await _persist();
    notifyListeners();
  }

  List<HabitTask> _insertTask(HabitTask task) {
    if (task.todayOnly) return [...tasks, task];
    final extrasStart = tasks.indexWhere((item) => item.todayOnly);
    if (extrasStart == -1) return [...tasks, task];
    return [
      ...tasks.sublist(0, extrasStart),
      task,
      ...tasks.sublist(extrasStart),
    ];
  }

  Future<void> upsertGoal(RewardGoal goal) async {
    final index = goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) {
      goals = [...goals, goal];
    } else {
      final copy = [...goals];
      copy[index] = goal;
      goals = copy;
    }
    await _persistGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(String goalId) async {
    goals = [for (final goal in goals) if (goal.id != goalId) goal];
    await _persistGoals();
    notifyListeners();
  }

  Future<void> reorderGoals(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final copy = [...goals];
    final goal = copy.removeAt(oldIndex);
    copy.insert(newIndex, goal);
    goals = copy;
    await _persistGoals();
    notifyListeners();
  }

  Future<bool> spendGoal(String goalId, {bool celebrate = true}) async {
    final index = goals.indexWhere((item) => item.id == goalId);
    if (index == -1) return false;
    final goal = goals[index];
    final next = await pointsRepo.spend(amount: goal.cost, goalId: goal.id);
    if (next == null) return false;
    totalPoints = next;
    goals = [for (final item in goals) if (item.id != goalId) item];
    await _persistGoals();
    if (celebrate && celebrateFor > Duration.zero) {
      celebrating = true;
      notifyListeners();
      await Future<void>.delayed(celebrateFor);
      celebrating = false;
    }
    notifyListeners();
    return true;
  }

  DayProgress? progressFor(String day) => history[day];

  Future<void> _ensureActivated() async {
    if (history.activatedOn != null) return;
    if (parentPassword == null || parentPassword!.isEmpty) return;
    history = history.withActivatedOn(todayStamp(now()));
    await historyRepo.save(history);
  }

  Future<void> _syncTodayHistory() {
    return _recordSnapshot(TaskSnapshot(day: todayStamp(now()), tasks: tasks));
  }

  Future<void> _recordSnapshot(TaskSnapshot snapshot) async {
    history = history.withDay(
      DayProgress.fromTasks(snapshot.day, snapshot.tasks),
    );
    await historyRepo.save(history);
  }

  Future<void> _persist() {
    return taskRepo.save(TaskSnapshot(day: todayStamp(now()), tasks: tasks));
  }

  Future<void> _persistGoals() {
    return goalRepo.save(goals);
  }

  Future<void> _update(
    String taskId,
    HabitTask Function(HabitTask task) change,
  ) async {
    tasks = [
      for (final task in tasks)
        if (task.id == taskId) change(task) else task,
    ];
    await _persist();
    await _syncTodayHistory();
    notifyListeners();
  }
}
