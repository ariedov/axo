import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/backup.dart';
import '../data/completion_bonus.dart';
import '../data/day_history_repository.dart';
import '../data/game_limit.dart';
import '../data/game_plays.dart';
import '../data/game_recents.dart';
import '../data/goal_repository.dart';
import '../data/models.dart';
import '../data/onboarding_flags.dart';
import '../data/parent_auth.dart';
import '../data/points_repository.dart';
import '../data/strikes_repository.dart';
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
    StrikesRepository? strikesRepo,
    GameLimitRepository? gameLimitRepo,
    CompletionBonusRepository? completionBonusRepo,
    GameRecentsRepository? gameRecents,
    this.celebrateFor = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : onboardingFlags = onboardingFlags ?? InMemoryOnboardingFlags(),
       strikesRepo = strikesRepo ?? InMemoryStrikesRepository(),
       gameLimitRepo = gameLimitRepo ?? InMemoryGameLimitRepository(),
       completionBonusRepo =
           completionBonusRepo ?? InMemoryCompletionBonusRepository(),
       gameRecents = gameRecents ?? InMemoryGameRecentsRepository(),
       now = now ?? DateTime.now;

  final PointsRepository pointsRepo;
  final TaskRepository taskRepo;
  final ParentAuth parentAuth;
  final GamePlaysRepository gamePlays;
  final GoalRepository goalRepo;
  final DayHistoryRepository historyRepo;
  final OnboardingFlags onboardingFlags;
  final StrikesRepository strikesRepo;
  final GameLimitRepository gameLimitRepo;
  final CompletionBonusRepository completionBonusRepo;
  final GameRecentsRepository gameRecents;
  final Duration celebrateFor;
  final DateTime Function() now;

  int totalPoints = 0;
  List<HabitTask> tasks = const [];
  Map<String, TaskSnapshot> days = const {};
  List<RewardGoal> goals = const [];
  bool ready = false;
  bool celebrating = false;
  String? parentPassword;
  bool onboardingComplete = false;
  GamePlaysSnapshot plays = const GamePlaysSnapshot();
  List<String> recentGameIds = const [];
  DayHistory history = const DayHistory();
  int strikes = 0;
  String? strikeDay;
  int penaltyPoints = AppConfig.defaultPenaltyPoints;
  bool gameLimitEnabled = AppConfig.defaultGameLimitEnabled;
  int rewardedPlays = AppConfig.rewardedPlays;
  int playLimitMinutes = AppConfig.playLimitMinutes;
  bool completionBonusEnabled = AppConfig.defaultCompletionBonusEnabled;
  int completionBonusPoints = AppConfig.defaultCompletionBonusPoints;

  Duration get playLimitWindow => Duration(minutes: playLimitMinutes);

  bool get canStrike => strikes < AppConfig.strikesToPenalty;

  bool get needsOnboarding => !onboardingComplete;

  bool get hasParentPassword =>
      parentPassword != null && parentPassword!.isNotEmpty;

  bool checkPassword(String value) =>
      hasParentPassword && value.trim() == parentPassword;

  int get pendingCount =>
      todayDailyTasks.where((task) => task.isPending).length;
  int get waitingCount =>
      todayDailyTasks.where((task) => task.isSubmitted).length;
  int get verifiedCount =>
      todayDailyTasks.where((task) => task.isVerified).length;
  int get todayEarnedPoints => todayDailyTasks
      .where((task) => task.isVerified)
      .fold(0, (sum, task) => sum + task.points);
  int get todayPossiblePoints =>
      todayDailyTasks.fold(0, (sum, task) => sum + task.points);
  int get extraEarnedPoints => extraTasks
      .where((task) => task.isVerified)
      .fold(0, (sum, task) => sum + task.points);
  int get extraPossiblePoints =>
      extraTasks.fold(0, (sum, task) => sum + task.points);

  /// Required tasks the child sees today — recurring tasks only on their
  /// days, one-offs always.
  List<HabitTask> get todayDailyTasks => [
    for (final task in tasks)
      if (task.isMandatory && task.showsOn(now())) task,
  ];

  /// Recurring mandatory tasks, used for editing and reordering. One-offs
  /// for today are managed from the home screen instead.
  List<HabitTask> get dailyTasks => [
    for (final task in tasks)
      if (task.isMandatory && !task.todayOnly) task,
  ];
  List<HabitTask> get dailyOptionalTasks => [
    for (final task in tasks)
      if (task.optional && !task.todayOnly) task,
  ];
  List<HabitTask> get extraTasks => [
    for (final task in tasks)
      if (task.optional && task.showsOn(now())) task,
  ];
  List<RewardGoal> get activeGoals => [
    for (final goal in goals)
      if (!goal.isCompleted) goal,
  ];
  List<RewardGoal> get completedGoals {
    final done = [
      for (final goal in goals)
        if (goal.isCompleted) goal,
    ];
    done.sort((a, b) => b.completedOn!.compareTo(a.completedOn!));
    return done;
  }

  Future<void> load() async {
    totalPoints = await pointsRepo.fetchTotal();
    final todayLoad = await taskRepo.loadToday();
    days = Map.of(todayLoad.days);
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
    plays = await gamePlays.load();
    recentGameIds = await gameRecents.load();
    history = await historyRepo.load();
    await _loadStrikes();
    await _loadGameLimit();
    await _loadCompletionBonus();
    await _prunePlays();
    for (final snapshot in days.values) {
      history = history.withDay(
        DayProgress.fromTasks(snapshot.day, snapshot.tasks),
      );
    }
    await historyRepo.save(history);
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

  Future<({int applied, bool penaltyHit})> addStrike() async {
    if (!canStrike) return (applied: 0, penaltyHit: false);
    final next = strikes + 1;
    final today = todayStamp(now());
    if (next < AppConfig.strikesToPenalty) {
      strikes = next;
      strikeDay = today;
      await _persistStrikes();
      notifyListeners();
      return (applied: 0, penaltyHit: false);
    }
    final applied = await adjustPoints(-penaltyPoints);
    strikes = AppConfig.strikesToPenalty;
    strikeDay = today;
    await _persistStrikes();
    notifyListeners();
    return (applied: applied, penaltyHit: true);
  }

  Future<void> clearStrikes() async {
    if (strikes == 0) return;
    strikes = 0;
    await _persistStrikes();
    notifyListeners();
  }

  Future<void> setPenaltyPoints(int amount) async {
    if (amount < 1) return;
    penaltyPoints = amount;
    await _persistStrikes();
    notifyListeners();
  }

  Future<void> setCompletionBonus({bool? enabled, int? points}) async {
    if (points != null && points < 1) return;
    var changed = false;
    if (enabled != null && enabled != completionBonusEnabled) {
      completionBonusEnabled = enabled;
      changed = true;
    }
    if (points != null && points != completionBonusPoints) {
      completionBonusPoints = points;
      changed = true;
    }
    if (!changed) return;
    await _persistCompletionBonus();
    notifyListeners();
  }

  Future<void> setGameLimit({
    bool? enabled,
    int? rounds,
    int? restMinutes,
  }) async {
    if (rounds != null && rounds < 1) return;
    if (restMinutes != null && restMinutes < 1) return;
    var changed = false;
    if (enabled != null && enabled != gameLimitEnabled) {
      gameLimitEnabled = enabled;
      changed = true;
    }
    if (rounds != null && rounds != rewardedPlays) {
      rewardedPlays = rounds;
      changed = true;
    }
    if (restMinutes != null && restMinutes != playLimitMinutes) {
      playLimitMinutes = restMinutes;
      changed = true;
    }
    if (!changed) return;
    await _persistGameLimit();
    await _prunePlays();
    notifyListeners();
  }

  Future<void> _loadStrikes() async {
    final snapshot = await strikesRepo.load();
    penaltyPoints = snapshot.penaltyPoints;
    final today = todayStamp(now());
    if (snapshot.count >= AppConfig.strikesToPenalty && snapshot.day != today) {
      strikes = 0;
      strikeDay = snapshot.day;
      await _persistStrikes();
      return;
    }
    strikes = snapshot.count;
    strikeDay = snapshot.day;
  }

  Future<void> _persistStrikes() {
    return strikesRepo.save(
      StrikeSnapshot(
        count: strikes,
        day: strikeDay,
        penaltyPoints: penaltyPoints,
      ),
    );
  }

  Future<void> _loadGameLimit() async {
    final snapshot = await gameLimitRepo.load();
    gameLimitEnabled = snapshot.enabled;
    rewardedPlays = snapshot.rewardedPlays < 1
        ? AppConfig.rewardedPlays
        : snapshot.rewardedPlays;
    playLimitMinutes = snapshot.playLimitMinutes < 1
        ? AppConfig.playLimitMinutes
        : snapshot.playLimitMinutes;
  }

  Future<void> _persistGameLimit() {
    return gameLimitRepo.save(
      GameLimitSnapshot(
        enabled: gameLimitEnabled,
        rewardedPlays: rewardedPlays,
        playLimitMinutes: playLimitMinutes,
      ),
    );
  }

  Future<void> _loadCompletionBonus() async {
    final snapshot = await completionBonusRepo.load();
    completionBonusEnabled = snapshot.enabled;
    completionBonusPoints = snapshot.points < 1
        ? AppConfig.defaultCompletionBonusPoints
        : snapshot.points;
  }

  Future<void> _persistCompletionBonus() {
    return completionBonusRepo.save(
      CompletionBonusSnapshot(
        enabled: completionBonusEnabled,
        points: completionBonusPoints,
      ),
    );
  }

  Future<void> _prunePlays() async {
    final pruned = plays.pruned(now(), window: playLimitWindow);
    if (pruned.rounds.length == plays.rounds.length) return;
    plays = pruned;
    await gamePlays.save(plays);
  }

  int playsUsed(String gameId) {
    final used = plays.usedToday(gameId, now());
    return used > rewardedPlays ? rewardedPlays : used;
  }

  int playsLeft(String gameId) {
    if (!gameLimitEnabled) return rewardedPlays;
    final left = rewardedPlays - playsUsed(gameId);
    return left < 0 ? 0 : left;
  }

  int get windowUsed {
    if (gamesLocked) return rewardedPlays;
    final n = plays.used(now(), window: playLimitWindow);
    return n > rewardedPlays ? rewardedPlays : n;
  }

  int get windowLeft {
    if (!gameLimitEnabled) return rewardedPlays;
    if (gamesLocked) return 0;
    final left = rewardedPlays - plays.used(now(), window: playLimitWindow);
    return left < 0 ? 0 : left;
  }

  DateTime? get playsUnlocksAt =>
      plays.unlocksAt(now(), window: playLimitWindow, cap: rewardedPlays);

  bool get gamesLocked => gameLimitEnabled && playsUnlocksAt != null;

  Duration get playsCooldown {
    final at = playsUnlocksAt;
    if (at == null) return Duration.zero;
    final left = at.difference(now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> markGamePlayed(String gameId) async {
    recentGameIds = [
      gameId,
      for (final id in recentGameIds)
        if (id != gameId) id,
    ];
    await gameRecents.save(recentGameIds);
    notifyListeners();
  }

  /// Records the round for the play window. With limits off, rounds still
  /// update per-game progress, while the award is never blocked by a cap.
  Future<int> tryAwardGamePlay(String gameId, {int? points}) async {
    final award = points ?? AppConfig.gamePlayPoints;
    if (!gameLimitEnabled) {
      plays = plays
          .increment(gameId, now())
          .pruned(now(), window: playLimitWindow);
      await gamePlays.save(plays);
      totalPoints = await pointsRepo.award(
        amount: award,
        taskId: 'game:$gameId',
      );
      notifyListeners();
      return award;
    }
    if (windowLeft <= 0) return 0;
    final scoredAward = playsLeft(gameId) <= 0 ? 0 : award;

    plays = plays
        .increment(gameId, now())
        .pruned(now(), window: playLimitWindow);
    await gamePlays.save(plays);
    if (scoredAward > 0) {
      totalPoints = await pointsRepo.award(
        amount: scoredAward,
        taskId: 'game:$gameId',
      );
    }
    notifyListeners();
    return scoredAward;
  }

  Future<void> submit(String taskId, {String? day}) {
    return _update(
      taskId,
      (task) =>
          task.isPending ? task.copyWith(status: TaskStatus.submitted) : task,
      day: day,
    );
  }

  Future<void> unsubmit(String taskId, {String? day}) {
    return _update(
      taskId,
      (task) =>
          task.isSubmitted ? task.copyWith(status: TaskStatus.pending) : task,
      day: day,
    );
  }

  Future<int> verify(String taskId, {String? day}) async {
    final task = _taskOn(taskId, day);
    if (task == null || !task.isSubmitted) return 0;

    final wasComplete = _mandatoryComplete(day);
    totalPoints = await pointsRepo.award(amount: task.points, taskId: task.id);
    final isToday = _isToday(day);
    celebrating = isToday;
    await _update(
      taskId,
      (item) => item.copyWith(status: TaskStatus.verified),
      day: day,
    );
    final bonus = await _maybeAwardCompletionBonus(
      day: day,
      wasComplete: wasComplete,
    );
    if (celebrating && celebrateFor > Duration.zero && bonus == 0) {
      await Future<void>.delayed(celebrateFor);
    }
    celebrating = false;
    notifyListeners();
    return bonus;
  }

  Future<void> reject(String taskId, {String? day}) =>
      unsubmit(taskId, day: day);

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
    tasks = [
      for (final task in tasks)
        if (task.id != taskId) task,
    ];
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
    notifyListeners();
    await _persist();
  }

  Future<void> reorderDailyTasks(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final daily = dailyTasks;
    final moved = daily.removeAt(oldIndex);
    daily.insert(newIndex, moved);
    var index = 0;
    tasks = [
      for (final task in tasks)
        if (task.isMandatory && !task.todayOnly) daily[index++] else task,
    ];
    notifyListeners();
    await _persist();
  }

  Future<void> reorderDailyOptionalTasks(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final optional = dailyOptionalTasks;
    final moved = optional.removeAt(oldIndex);
    optional.insert(newIndex, moved);
    var index = 0;
    tasks = [
      for (final task in tasks)
        if (task.optional && !task.todayOnly) optional[index++] else task,
    ];
    notifyListeners();
    await _persist();
  }

  List<HabitTask> _insertTask(HabitTask task) {
    if (task.todayOnly) return [...tasks, task];
    if (task.optional) {
      final extrasStart = tasks.indexWhere((item) => item.todayOnly);
      if (extrasStart == -1) return [...tasks, task];
      return [
        ...tasks.sublist(0, extrasStart),
        task,
        ...tasks.sublist(extrasStart),
      ];
    }
    final restStart = tasks.indexWhere(
      (item) => item.optional || item.todayOnly,
    );
    if (restStart == -1) return [...tasks, task];
    return [...tasks.sublist(0, restStart), task, ...tasks.sublist(restStart)];
  }

  Future<void> upsertGoal(RewardGoal goal) async {
    final index = goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) {
      goals = [...goals, goal];
    } else {
      final copy = [...goals];
      copy[index] = goal.copyWith(completedOn: copy[index].completedOn);
      goals = copy;
    }
    await _persistGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(String goalId) async {
    goals = [
      for (final goal in goals)
        if (goal.id != goalId) goal,
    ];
    await _persistGoals();
    notifyListeners();
  }

  Future<void> reorderGoals(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final active = activeGoals;
    final moved = active.removeAt(oldIndex);
    active.insert(newIndex, moved);
    var index = 0;
    goals = [
      for (final goal in goals)
        if (goal.isCompleted) goal else active[index++],
    ];
    notifyListeners();
    await _persistGoals();
  }

  Future<bool> spendGoal(String goalId, {bool celebrate = true}) async {
    final index = goals.indexWhere((item) => item.id == goalId);
    if (index == -1) return false;
    final goal = goals[index];
    if (goal.isCompleted) return false;
    final next = await pointsRepo.spend(amount: goal.cost, goalId: goal.id);
    if (next == null) return false;
    totalPoints = next;
    goals = [
      for (final item in goals)
        if (item.id == goalId)
          item.copyWith(completedOn: now().toIso8601String())
        else
          item,
    ];
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

  int get streak => history.currentStreak(todayStamp(now()));

  List<HabitTask> tasksOn(String day) {
    final list = _isToday(day) ? tasks : days[day]?.tasks ?? const [];
    final date = _isToday(day) ? now() : dateFromStamp(day);
    return [
      for (final task in list)
        if (task.showsOn(date)) task,
    ];
  }

  bool canCompleteDay(String day) {
    final today = todayStamp(now());
    if (day.compareTo(today) > 0) return false;
    if (day == today) return true;
    return days.containsKey(day);
  }

  BackupSnapshot exportBackup() {
    final today = TaskSnapshot(day: todayStamp(now()), tasks: tasks);
    return BackupSnapshot(
      exportedAt: now(),
      points: totalPoints,
      onboardingComplete: onboardingComplete,
      tasks: today,
      taskDays: {...days, today.day: today},
      goals: goals,
      history: history,
      plays: plays,
      strikes: strikes,
      strikeDay: strikeDay,
      penaltyPoints: penaltyPoints,
      gameLimitEnabled: gameLimitEnabled,
      rewardedPlays: rewardedPlays,
      playLimitMinutes: playLimitMinutes,
      completionBonusEnabled: completionBonusEnabled,
      completionBonusPoints: completionBonusPoints,
    );
  }

  Future<void> importBackup(BackupSnapshot snapshot) async {
    await pointsRepo.setTotal(snapshot.points);
    await taskRepo.replaceAll(snapshot.allTaskDays);
    await goalRepo.save(snapshot.goals);
    await historyRepo.save(snapshot.history);
    await gamePlays.save(snapshot.plays);
    await onboardingFlags.setComplete(snapshot.onboardingComplete);
    await strikesRepo.save(
      StrikeSnapshot(
        count: snapshot.strikes,
        day: snapshot.strikeDay,
        penaltyPoints: snapshot.penaltyPoints,
      ),
    );
    await gameLimitRepo.save(
      GameLimitSnapshot(
        enabled: snapshot.gameLimitEnabled,
        rewardedPlays: snapshot.rewardedPlays,
        playLimitMinutes: snapshot.playLimitMinutes,
      ),
    );
    await completionBonusRepo.save(
      CompletionBonusSnapshot(
        enabled: snapshot.completionBonusEnabled,
        points: snapshot.completionBonusPoints,
      ),
    );
    await load();
  }

  Future<void> _ensureActivated() async {
    if (history.activatedOn != null) return;
    if (!onboardingComplete) return;
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
    final snapshot = TaskSnapshot(day: todayStamp(now()), tasks: tasks);
    days = {...days, snapshot.day: snapshot};
    return taskRepo.save(snapshot);
  }

  Future<void> _persistGoals() {
    return goalRepo.save(goals);
  }

  bool _isToday(String? day) {
    return day == null || day == todayStamp(now());
  }

  bool _mandatoryComplete(String? day) {
    final mandatory = [
      for (final task in tasksOn(day ?? todayStamp(now())))
        if (task.isMandatory) task,
    ];
    return mandatory.isNotEmpty && mandatory.every((task) => task.isVerified);
  }

  Future<int> _maybeAwardCompletionBonus({
    required String? day,
    required bool wasComplete,
  }) async {
    if (!completionBonusEnabled || completionBonusPoints < 1) return 0;
    if (wasComplete || !_mandatoryComplete(day)) return 0;
    final stamp = day ?? todayStamp(now());
    if (history.bonusOn(stamp)) return 0;
    totalPoints = await pointsRepo.award(
      amount: completionBonusPoints,
      taskId: 'bonus:$stamp',
    );
    history = history.withBonusDay(stamp);
    await historyRepo.save(history);
    notifyListeners();
    return completionBonusPoints;
  }

  HabitTask? _taskOn(String taskId, String? day) {
    for (final task in tasksOn(_isToday(day) ? todayStamp(now()) : day!)) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  Future<void> _update(
    String taskId,
    HabitTask Function(HabitTask task) change, {
    String? day,
  }) async {
    if (_isToday(day)) {
      tasks = [
        for (final task in tasks)
          if (task.id == taskId) change(task) else task,
      ];
      await _persist();
      await _syncTodayHistory();
      notifyListeners();
      return;
    }
    final snapshot = days[day];
    if (snapshot == null) return;
    final updated = TaskSnapshot(
      day: snapshot.day,
      tasks: [
        for (final task in snapshot.tasks)
          if (task.id == taskId) change(task) else task,
      ],
    );
    days = {...days, updated.day: updated};
    await taskRepo.save(updated);
    await _recordSnapshot(updated);
    notifyListeners();
  }
}
