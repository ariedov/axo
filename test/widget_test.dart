import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app/config.dart';
import 'package:app/data/answer.dart';
import 'package:app/data/backup.dart';
import 'package:app/data/completion_bonus.dart';
import 'package:app/data/day_history_repository.dart';
import 'package:app/data/division_problem.dart';
import 'package:app/data/game_catalog.dart';
import 'package:app/data/game_limit.dart';
import 'package:app/data/game_plays.dart';
import 'package:app/data/game_recents.dart';
import 'package:app/data/game_round.dart';
import 'package:app/data/memory_deck.dart';
import 'package:app/data/shuffled_deck.dart';
import 'package:app/data/simon_sequence.dart';
import 'package:app/data/times_tables_problem.dart';
import 'package:app/data/goal_repository.dart';
import 'package:app/data/models.dart';
import 'package:app/data/onboarding_flags.dart';
import 'package:app/data/parent_auth.dart';
import 'package:app/data/points_repository.dart';
import 'package:app/data/strikes_repository.dart';
import 'package:app/data/task_repository.dart';
import 'package:app/data/today.dart';
import 'package:app/main.dart';
import 'package:app/screens/division_screen.dart';
import 'package:app/screens/games_screen.dart';
import 'package:app/screens/memory_screen.dart';
import 'package:app/screens/parent_settings_screen.dart';
import 'package:app/screens/simon_screen.dart';
import 'package:app/state/habit_scope.dart';
import 'package:app/state/habit_store.dart';
import 'package:app/strings.dart';
import 'package:app/theme.dart';
import 'package:app/widgets/answer_flash.dart';
import 'package:app/widgets/axolotl_mascot.dart';
import 'package:app/widgets/game_input_body.dart';
import 'package:app/widgets/game_plays_banner.dart';
import 'package:app/widgets/game_scaffold.dart';
import 'package:app/widgets/game_setup_body.dart';
import 'package:app/widgets/task_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

HabitStore testStore({
  int points = 0,
  List<HabitTask> tasks = const [],
  List<RewardGoal> goals = const [],
  String? password = '4826',
  int strikes = 0,
  String? strikeDay,
  int penaltyPoints = AppConfig.defaultPenaltyPoints,
  int rewardedPlays = AppConfig.rewardedPlays,
  int playLimitMinutes = AppConfig.playLimitMinutes,
  bool completionBonusEnabled = AppConfig.defaultCompletionBonusEnabled,
  int completionBonusPoints = AppConfig.defaultCompletionBonusPoints,
  GameRecentsRepository? gameRecents,
  DayHistory? history,
  DateTime Function()? now,
}) {
  return HabitStore(
    pointsRepo: InMemoryPointsRepository(points),
    taskRepo: InMemoryTaskRepository(
      TaskSnapshot(day: todayStamp(now?.call()), tasks: tasks),
    ),
    parentAuth: InMemoryParentAuth(password),
    gamePlays: InMemoryGamePlaysRepository(),
    gameRecents: gameRecents,
    goalRepo: InMemoryGoalRepository([...goals]),
    historyRepo: InMemoryDayHistoryRepository(history ?? const DayHistory()),
    strikesRepo: InMemoryStrikesRepository(
      StrikeSnapshot(
        count: strikes,
        day: strikeDay,
        penaltyPoints: penaltyPoints,
      ),
    ),
    gameLimitRepo: InMemoryGameLimitRepository(
      GameLimitSnapshot(
        rewardedPlays: rewardedPlays,
        playLimitMinutes: playLimitMinutes,
      ),
    ),
    completionBonusRepo: InMemoryCompletionBonusRepository(
      CompletionBonusSnapshot(
        enabled: completionBonusEnabled,
        points: completionBonusPoints,
      ),
    ),
    celebrateFor: Duration.zero,
    now: now,
  );
}

Future<void> openParentSetting(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> pumpParentSettings(WidgetTester tester, HabitStore store) async {
  await tester.pumpWidget(
    HabitScope(
      store: store,
      child: MaterialApp(
        theme: AppTheme.cute,
        home: const ParentSettingsScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('answers match ignoring case and extra spaces', () {
    expect(answersMatch('  Cat  ', 'cat'), isTrue);
    expect(answersMatch('CAT', 'cat'), isTrue);
    expect(answersMatch('кіт', 'КІТ'), isTrue);
    expect(answersMatch('  Кіт', 'кіт'), isTrue);
    expect(answersMatch('dog', 'кіт'), isFalse);
    expect(answersMatch('   ', 'cat'), isFalse);
  });

  test('every spelling and translation picture has an icon', () {
    final files = [
      'assets/data/spelling_words.json',
      'assets/data/translations.json',
    ];
    for (final path in files) {
      final items = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
      for (final item in items) {
        final emoji = (item as Map<String, dynamic>)['emoji'] as String;
        expect(
          PictureIcons.knows(emoji),
          isTrue,
          reason: 'missing icon for $emoji in $path',
        );
      }
    }
  });

  test('Ukrainian points pluralization', () {
    expect(S.pointsWord(1), '1 бал');
    expect(S.pointsWord(2), '2 бали');
    expect(S.pointsWord(5), '5 балів');
    expect(S.pointsWord(11), '11 балів');
    expect(S.pointsWord(21), '21 бал');
  });

  test('Ukrainian streak pluralization', () {
    expect(S.daysWord(1), '1 день');
    expect(S.daysWord(2), '2 дні');
    expect(S.daysWord(5), '5 днів');
    expect(S.daysWord(11), '11 днів');
    expect(S.daysWord(21), '21 день');
    expect(S.streak(5), '5 днів поспіль');
  });

  test('Ukrainian rounds and minutes pluralization', () {
    expect(S.roundsWord(1), '1 раунд');
    expect(S.roundsWord(2), '2 раунди');
    expect(S.roundsWord(5), '5 раундів');
    expect(S.minutesWord(1), '1 хвилина');
    expect(S.minutesWord(2), '2 хвилини');
    expect(S.minutesWord(15), '15 хвилин');
    expect(
      S.practiceOnly(5, 15),
      'Можна зіграти 5 раундів, далі 15 хвилин перерви. У раунді — 10 завдань.',
    );
  });

  test('onboarding is remembered after a reload', () async {
    final flags = InMemoryOnboardingFlags();
    final auth = InMemoryParentAuth();
    final points = InMemoryPointsRepository();
    final goals = InMemoryGoalRepository();

    Future<HabitStore> open() async {
      final store = HabitStore(
        pointsRepo: points,
        taskRepo: InMemoryTaskRepository(
          TaskSnapshot(day: todayStamp(), tasks: const []),
        ),
        parentAuth: auth,
        gamePlays: InMemoryGamePlaysRepository(),
        goalRepo: goals,
        historyRepo: InMemoryDayHistoryRepository(),
        onboardingFlags: flags,
        celebrateFor: Duration.zero,
      );
      await store.load();
      return store;
    }

    var store = await open();
    expect(store.needsOnboarding, isTrue);

    await store.completeOnboarding(
      password: 'mama',
      startingPoints: 40,
      goal: const RewardGoal(
        id: 'ice',
        title: 'Морозиво',
        cost: 50,
        icon: 'gift',
      ),
    );
    expect(store.needsOnboarding, isFalse);
    expect(store.totalPoints, 40);

    store = await open();
    expect(store.needsOnboarding, isFalse);
    expect(store.parentPassword, 'mama');
    expect(store.totalPoints, 40);
    expect(store.goals.single.title, 'Морозиво');
  });

  test('submit waits for parent before awarding points', () async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();

    await store.submit('bed');
    expect(store.tasks.first.isSubmitted, isTrue);
    expect(store.totalPoints, 0);
    expect(store.todayEarnedPoints, 0);
    expect(store.todayPossiblePoints, 10);

    await store.verify('bed');
    expect(store.tasks.first.isVerified, isTrue);
    expect(store.totalPoints, 20);
    expect(store.todayEarnedPoints, 10);
    expect(store.todayPossiblePoints, 10);
  });

  test(
    'completion bonus is awarded when the last mandatory task is verified',
    () async {
      final store = testStore(
        tasks: const [
          HabitTask(id: 'a', title: 'Перше', points: 5, icon: 'star'),
          HabitTask(id: 'b', title: 'Друге', points: 5, icon: 'bed'),
          HabitTask(
            id: 'help',
            title: 'Допомогти',
            points: 8,
            icon: 'star',
            optional: true,
          ),
        ],
      );
      await store.load();

      await store.submit('a');
      expect(await store.verify('a'), 0);
      expect(store.totalPoints, 5);

      await store.submit('help');
      expect(await store.verify('help'), 0);
      expect(store.totalPoints, 13);

      await store.submit('b');
      expect(await store.verify('b'), 10);
      expect(store.totalPoints, 28);
    },
  );

  test('completion bonus can be disabled or resized', () async {
    final store = testStore(
      completionBonusEnabled: false,
      completionBonusPoints: 25,
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    await store.submit('bed');
    expect(await store.verify('bed'), 0);
    expect(store.totalPoints, 10);

    await store.setCompletionBonus(enabled: true, points: 25);
    expect(store.completionBonusEnabled, isTrue);
    expect(store.completionBonusPoints, 25);

    final again = testStore(
      completionBonusEnabled: true,
      completionBonusPoints: 25,
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await again.load();
    await again.submit('bed');
    expect(await again.verify('bed'), 25);
    expect(again.totalPoints, 35);

    await again.setCompletionBonus(enabled: false);
    expect(again.completionBonusEnabled, isFalse);
    await again.setCompletionBonus(points: 0);
    expect(again.completionBonusPoints, 25);
  });

  test('today task points count verified against the full list', () async {
    final store = testStore(
      tasks: const [
        HabitTask(
          id: 'bed',
          title: 'Застелити ліжко',
          points: 10,
          icon: 'bed',
          status: TaskStatus.verified,
        ),
        HabitTask(id: 'teeth', title: 'Зуби', points: 15, icon: 'hygiene'),
      ],
    );
    await store.load();

    expect(store.todayEarnedPoints, 10);
    expect(store.todayPossiblePoints, 25);
    expect(S.todayTaskPoints(10, 25), '10 / 25 балів');
  });

  test('rejecting a task does not award points', () async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    await store.submit('bed');
    await store.reject('bed');
    expect(store.tasks.first.isPending, isTrue);
    expect(store.totalPoints, 0);
  });

  test('parent can reorder daily tasks', () async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'a', title: 'Перше', points: 5, icon: 'star'),
        HabitTask(id: 'b', title: 'Друге', points: 5, icon: 'bed'),
        HabitTask(id: 'c', title: 'Третє', points: 5, icon: 'food'),
      ],
    );
    await store.load();
    await store.reorderTasks(0, 1);
    expect(store.tasks.map((task) => task.id), ['b', 'a', 'c']);
    await store.reorderTasks(2, 0);
    expect(store.tasks.map((task) => task.id), ['c', 'b', 'a']);
  });

  test('today-only extras stay off the daily list', () async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    await store.upsertTask(
      const HabitTask(
        id: 'park',
        title: 'Прогулянка',
        points: 15,
        icon: 'walk',
        todayOnly: true,
      ),
    );
    expect(store.tasks.map((task) => task.id), ['bed', 'park']);
    expect(store.dailyTasks.map((task) => task.id), ['bed']);

    await store.upsertTask(
      const HabitTask(id: 'teeth', title: 'Зуби', points: 5, icon: 'hygiene'),
    );
    expect(store.tasks.map((task) => task.id), ['bed', 'teeth', 'park']);
    expect(store.dailyTasks.map((task) => task.id), ['bed', 'teeth']);

    await store.reorderDailyTasks(0, 1);
    expect(store.dailyTasks.map((task) => task.id), ['teeth', 'bed']);
    expect(store.tasks.map((task) => task.id), ['teeth', 'bed', 'park']);
  });

  test('optional daily tasks stay off the mandatory list', () async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    await store.upsertTask(
      const HabitTask(
        id: 'help',
        title: 'Допомогти',
        points: 8,
        icon: 'star',
        optional: true,
      ),
    );
    await store.upsertTask(
      const HabitTask(
        id: 'park',
        title: 'Прогулянка',
        points: 15,
        icon: 'walk',
        todayOnly: true,
        optional: true,
      ),
    );

    expect(store.tasks.map((task) => task.id), ['bed', 'help', 'park']);
    expect(store.dailyTasks.map((task) => task.id), ['bed']);
    expect(store.dailyOptionalTasks.map((task) => task.id), ['help']);
    expect(store.extraTasks.map((task) => task.id), ['help', 'park']);
    expect(store.todayPossiblePoints, 10);
    expect(store.extraPossiblePoints, 23);
    expect(store.pendingCount, 1);

    await store.upsertTask(
      const HabitTask(id: 'teeth', title: 'Зуби', points: 5, icon: 'hygiene'),
    );
    expect(store.tasks.map((task) => task.id), [
      'bed',
      'teeth',
      'help',
      'park',
    ]);

    await store.reorderDailyOptionalTasks(0, 0);
    await store.upsertTask(
      const HabitTask(
        id: 'read',
        title: 'Почитати',
        points: 5,
        icon: 'book',
        optional: true,
      ),
    );
    expect(store.dailyOptionalTasks.map((task) => task.id), ['help', 'read']);
    await store.reorderDailyOptionalTasks(0, 1);
    expect(store.dailyOptionalTasks.map((task) => task.id), ['read', 'help']);
    expect(store.dailyTasks.map((task) => task.id), ['bed', 'teeth']);
    expect(store.tasks.map((task) => task.id), [
      'bed',
      'teeth',
      'read',
      'help',
      'park',
    ]);
  });

  test('legacy json without optional is mandatory', () {
    final task = HabitTask.fromJson({
      'id': 'bed',
      'title': 'Застелити ліжко',
      'points': 10,
      'icon': 'bed',
      'status': 'pending',
      'todayOnly': false,
    });
    expect(task.optional, isFalse);
    expect(task.isMandatory, isTrue);
    expect(task.toJson()['optional'], isFalse);
  });

  test('task weekdays default to every day and ignore junk', () {
    final task = HabitTask.fromJson({
      'id': 'bed',
      'title': 'Застелити ліжко',
      'points': 10,
      'icon': 'bed',
    });
    expect(task.weekdays, isEmpty);
    expect(task.showsOn(DateTime(2026, 9, 5)), isTrue);

    final junk = HabitTask.fromJson({
      'id': 'bed',
      'title': 'Застелити ліжко',
      'points': 10,
      'icon': 'bed',
      'weekdays': [9, 0, 6.0, '3', 7],
    });
    expect(junk.weekdays, [DateTime.saturday, DateTime.sunday]);
    expect(junk.showsOn(DateTime(2026, 9, 5)), isTrue);
    expect(junk.showsOn(DateTime(2026, 9, 7)), isFalse);
    expect(junk.toJson()['weekdays'], [6, 7]);
  });

  test('goals can be saved, reordered, and spent', () async {
    final store = testStore(
      points: 80,
      goals: const [
        RewardGoal(id: 'ice', title: 'Морозиво', cost: 50, icon: 'gift'),
        RewardGoal(id: 'park', title: 'Парк', cost: 100, icon: 'walk'),
      ],
    );
    await store.load();
    expect(
      store.goals.singleWhere((goal) => goal.id == 'ice').canAfford(80),
      isTrue,
    );
    expect(
      store.goals.singleWhere((goal) => goal.id == 'park').canAfford(80),
      isFalse,
    );

    await store.reorderGoals(0, 1);
    expect(store.goals.map((goal) => goal.id), ['park', 'ice']);

    expect(await store.spendGoal('ice'), isTrue);
    expect(store.totalPoints, 30);
    expect(store.activeGoals.map((goal) => goal.id), ['park']);
    expect(store.completedGoals.single.id, 'ice');
    expect(store.completedGoals.single.isCompleted, isTrue);
    expect(store.goals, hasLength(2));

    expect(await store.spendGoal('ice'), isFalse);
    expect(await store.spendGoal('park'), isFalse);
    expect(store.totalPoints, 30);
    expect(store.activeGoals, hasLength(1));
  });

  test('export backup has family data and omits the parent password', () async {
    final store = testStore(
      points: 40,
      password: 'secret-pass',
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
      goals: const [
        RewardGoal(
          id: 'ice',
          title: 'Морозиво',
          cost: 50,
          icon: 'gift',
          completedOn: '2026-08-29T10:00:00.000',
        ),
      ],
    );
    await store.load();

    final snapshot = store.exportBackup();
    expect(snapshot.fileName, startsWith('axo-'));
    expect(snapshot.fileName, endsWith('.json'));

    final json = snapshot.toJson();
    expect(json['app'], BackupSnapshot.appId);
    expect(json['format'], BackupSnapshot.format);
    expect(json['data']['points'], 40);
    expect(json['data']['onboardingComplete'], isTrue);
    expect((json['data']['tasks'] as Map)['tasks'], isNotEmpty);
    expect(json['data']['taskDays'], isA<Map<String, dynamic>>());
    expect((json['data']['taskDays'] as Map).values, isNotEmpty);
    expect((json['data']['goals'] as List).single['completedOn'], isNotNull);
    expect(json['data']['history'], isA<Map<String, dynamic>>());
    expect(json['data']['gamePlays'], isA<Map<String, dynamic>>());
    expect(json['data']['strikes'], 0);
    expect(json['data']['penaltyPoints'], AppConfig.defaultPenaltyPoints);
    expect(json['data']['rewardedPlays'], AppConfig.rewardedPlays);
    expect(json['data']['playLimitMinutes'], AppConfig.playLimitMinutes);
    expect(
      json['data']['completionBonusEnabled'],
      AppConfig.defaultCompletionBonusEnabled,
    );
    expect(
      json['data']['completionBonusPoints'],
      AppConfig.defaultCompletionBonusPoints,
    );

    final encoded = snapshot.encode();
    expect(encoded.contains('secret-pass'), isFalse);
    expect(encoded.contains('parent_password'), isFalse);

    final restored = BackupSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(restored.points, 40);
    expect(restored.tasks.tasks.single.id, 'bed');
    expect(restored.taskDays.values.single.tasks.single.id, 'bed');
    expect(restored.tasks.tasks.single.optional, isFalse);
    expect(restored.goals.single.isCompleted, isTrue);
    expect(restored.onboardingComplete, isTrue);

    expect(
      () => BackupSnapshot.fromJson({
        'app': 'axo',
        'format': BackupSnapshot.format + 1,
        'exportedAt': '2026-08-29T00:00:00.000Z',
        'data': <String, dynamic>{},
      }),
      throwsFormatException,
    );
  });

  test('import backup replaces family data and keeps the password', () async {
    final source = testStore(
      points: 40,
      password: 'secret-pass',
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
      goals: const [
        RewardGoal(
          id: 'ice',
          title: 'Морозиво',
          cost: 50,
          icon: 'gift',
          completedOn: '2026-08-29T10:00:00.000',
        ),
      ],
    );
    await source.load();
    await source.tryAwardGamePlay(AppConfig.timesTablesGame, points: 3);
    final snapshot = source.exportBackup();

    final target = testStore(
      points: 99,
      password: 'keep-me',
      tasks: const [
        HabitTask(id: 'other', title: 'Інше', points: 5, icon: 'star'),
      ],
      goals: const [
        RewardGoal(id: 'park', title: 'Парк', cost: 100, icon: 'walk'),
      ],
    );
    await target.load();
    await target.importBackup(snapshot);

    expect(target.parentPassword, 'keep-me');
    expect(target.totalPoints, 43);
    expect(target.tasks.single.id, 'bed');
    expect(target.goals.single.id, 'ice');
    expect(target.goals.single.isCompleted, isTrue);
    expect(target.playsUsed(AppConfig.timesTablesGame), 1);
    expect(target.onboardingComplete, isTrue);
    expect(target.strikes, 0);
    expect(target.penaltyPoints, AppConfig.defaultPenaltyPoints);
    expect(target.rewardedPlays, AppConfig.rewardedPlays);
    expect(target.playLimitMinutes, AppConfig.playLimitMinutes);
    expect(
      target.completionBonusEnabled,
      AppConfig.defaultCompletionBonusEnabled,
    );
    expect(
      target.completionBonusPoints,
      AppConfig.defaultCompletionBonusPoints,
    );
  });

  test(
    'backup keeps optional flags and imports old files without them',
    () async {
      final source = testStore(
        tasks: const [
          HabitTask(
            id: 'bed',
            title: 'Застелити ліжко',
            points: 10,
            icon: 'bed',
          ),
          HabitTask(
            id: 'help',
            title: 'Допомогти',
            points: 8,
            icon: 'star',
            optional: true,
          ),
        ],
      );
      await source.load();
      final encoded = source.exportBackup().encode();
      expect(encoded.contains('"optional": true'), isTrue);

      final restored = BackupSnapshot.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(restored.tasks.tasks.map((task) => task.optional), [false, true]);

      final legacy = BackupSnapshot.fromJson({
        'app': 'axo',
        'format': 1,
        'exportedAt': '2026-08-29T00:00:00.000Z',
        'data': {
          'points': 0,
          'onboardingComplete': true,
          'tasks': {
            'day': '2026-08-29',
            'tasks': [
              {
                'id': 'bed',
                'title': 'Застелити ліжко',
                'points': 10,
                'icon': 'bed',
                'status': 'pending',
                'todayOnly': false,
              },
            ],
          },
          'goals': <Map<String, dynamic>>[],
          'history': <String, dynamic>{},
          'gamePlays': {'day': '2026-08-29', 'counts': <String, dynamic>{}},
        },
      });
      expect(legacy.tasks.tasks.single.optional, isFalse);
      expect(legacy.taskDays.keys, ['2026-08-29']);
    },
  );

  test('backup keeps task weekdays and old files stay daily', () async {
    final source = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
        HabitTask(
          id: 'homework',
          title: 'Домашнє завдання',
          points: 20,
          icon: 'homework',
          weekdays: [DateTime.saturday, DateTime.sunday],
        ),
      ],
    );
    await source.load();

    final encoded = source.exportBackup().encode();
    expect(encoded.contains('weekdays'), isTrue);

    final restored = BackupSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(restored.tasks.tasks.map((task) => task.weekdays), [
      const <int>[],
      const [DateTime.saturday, DateTime.sunday],
    ]);

    final target = testStore(
      tasks: const [
        HabitTask(id: 'other', title: 'Інше', points: 5, icon: 'star'),
      ],
    );
    await target.load();
    await target.importBackup(restored);
    expect(target.dailyTasks.map((task) => task.weekdays), [
      const <int>[],
      const [DateTime.saturday, DateTime.sunday],
    ]);
  });

  test('a new day resets progress but keeps the task list', () async {
    final memory = <String, String>{};
    final verified = const HabitTask(
      id: 'bed',
      title: 'Застелити ліжко',
      points: 10,
      icon: 'bed',
      status: TaskStatus.verified,
    );
    memory['tasks_snapshot'] = jsonEncode(
      TaskSnapshot(day: '2026-08-26', tasks: [verified]).toJson(),
    );

    final repo = LocalTaskRepository(
      (key) async => memory[key],
      (key, value) async => memory[key] = value,
      now: () => DateTime(2026, 8, 27),
    );

    final loaded = await repo.loadToday();
    expect(loaded.current.day, '2026-08-27');
    expect(loaded.current.tasks.single.title, 'Застелити ліжко');
    expect(loaded.current.tasks.single.isPending, isTrue);
    expect(loaded.previous?.day, '2026-08-26');
    expect(loaded.previous?.tasks.single.isVerified, isTrue);
    expect((await repo.loadDay('2026-08-26'))?.tasks.single.isVerified, isTrue);
  });

  test('today-only tasks disappear the next day', () async {
    final memory = <String, String>{};
    memory['tasks_snapshot'] = jsonEncode(
      TaskSnapshot(
        day: '2026-08-26',
        tasks: const [
          HabitTask(
            id: 'bed',
            title: 'Застелити ліжко',
            points: 10,
            icon: 'bed',
            status: TaskStatus.verified,
          ),
          HabitTask(
            id: 'park',
            title: 'Прогулянка',
            points: 15,
            icon: 'walk',
            todayOnly: true,
            status: TaskStatus.verified,
          ),
        ],
      ).toJson(),
    );

    final repo = LocalTaskRepository(
      (key) async => memory[key],
      (key, value) async => memory[key] = value,
      now: () => DateTime(2026, 8, 27),
    );

    final loaded = await repo.loadToday();
    expect(loaded.current.tasks, hasLength(1));
    expect(loaded.current.tasks.single.id, 'bed');
    expect(loaded.current.tasks.single.isPending, isTrue);
    expect(loaded.previous?.tasks, hasLength(2));
  });

  test('optional daily tasks reset the next day', () async {
    final memory = <String, String>{};
    memory['tasks_snapshot'] = jsonEncode(
      TaskSnapshot(
        day: '2026-08-26',
        tasks: const [
          HabitTask(
            id: 'bed',
            title: 'Застелити ліжко',
            points: 10,
            icon: 'bed',
            status: TaskStatus.verified,
          ),
          HabitTask(
            id: 'help',
            title: 'Допомогти',
            points: 8,
            icon: 'star',
            optional: true,
            status: TaskStatus.verified,
          ),
          HabitTask(
            id: 'park',
            title: 'Прогулянка',
            points: 15,
            icon: 'walk',
            todayOnly: true,
            optional: true,
            status: TaskStatus.verified,
          ),
        ],
      ).toJson(),
    );

    final repo = LocalTaskRepository(
      (key) async => memory[key],
      (key, value) async => memory[key] = value,
      now: () => DateTime(2026, 8, 27),
    );

    final loaded = await repo.loadToday();
    expect(loaded.current.tasks.map((task) => task.id), ['bed', 'help']);
    expect(loaded.current.tasks.every((task) => task.isPending), isTrue);
    expect(loaded.current.tasks.last.optional, isTrue);
    expect(loaded.previous?.tasks, hasLength(3));
  });

  test('yesterday progress is saved when the day rolls over', () async {
    final memory = <String, String>{};
    final tasks = [
      const HabitTask(
        id: 'bed',
        title: 'Застелити ліжко',
        points: 10,
        icon: 'bed',
        status: TaskStatus.verified,
      ),
      const HabitTask(
        id: 'teeth',
        title: 'Зуби',
        points: 10,
        icon: 'hygiene',
        status: TaskStatus.pending,
      ),
    ];
    memory['tasks_snapshot'] = jsonEncode(
      TaskSnapshot(day: '2026-08-26', tasks: tasks).toJson(),
    );
    final clock = DateTime(2026, 8, 27);
    final store = HabitStore(
      pointsRepo: InMemoryPointsRepository(),
      taskRepo: LocalTaskRepository(
        (key) async => memory[key],
        (key, value) async => memory[key] = value,
        now: () => clock,
      ),
      parentAuth: InMemoryParentAuth('mama'),
      gamePlays: InMemoryGamePlaysRepository(),
      goalRepo: InMemoryGoalRepository(),
      historyRepo: InMemoryDayHistoryRepository(),
      celebrateFor: Duration.zero,
      now: () => clock,
    );
    await store.load();

    final yesterday = store.progressFor('2026-08-26')!;
    expect(yesterday.completed, 1);
    expect(yesterday.total, 2);
    expect(yesterday.isPartial, isTrue);
    expect(store.history.activatedOn, '2026-08-27');
    expect(store.tasks.every((task) => task.isPending), isTrue);
  });

  test('verifying tasks fills today progress from none to full', () async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'a', title: 'Перше', points: 5, icon: 'star'),
        HabitTask(id: 'b', title: 'Друге', points: 5, icon: 'bed'),
      ],
    );
    await store.load();
    expect(store.progressFor(todayStamp())?.completed, 0);
    expect(store.progressFor(todayStamp())?.isFull, isFalse);

    await store.submit('a');
    await store.verify('a');
    expect(store.progressFor(todayStamp())?.isPartial, isTrue);

    await store.submit('b');
    await store.verify('b');
    expect(store.progressFor(todayStamp())?.isFull, isTrue);
    expect(store.progressFor(todayStamp())?.completed, 2);
  });

  test('optional tasks do not affect calendar completion', () async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
        HabitTask(
          id: 'help',
          title: 'Допомогти вдома',
          points: 8,
          icon: 'star',
          optional: true,
        ),
        HabitTask(
          id: 'park',
          title: 'Прогулянка',
          points: 15,
          icon: 'walk',
          todayOnly: true,
          optional: true,
        ),
      ],
    );
    await store.load();
    expect(store.progressFor(todayStamp())?.total, 1);
    expect(store.progressFor(todayStamp())?.completed, 0);
    expect(store.progressFor(todayStamp())?.isFull, isFalse);
    expect(store.progressFor(todayStamp())?.isPartial, isFalse);

    await store.submit('help');
    await store.verify('help');
    expect(store.progressFor(todayStamp())?.completed, 0);
    expect(store.progressFor(todayStamp())?.isFull, isFalse);
    expect(store.progressFor(todayStamp())?.isPartial, isFalse);

    await store.submit('bed');
    await store.verify('bed');
    expect(store.progressFor(todayStamp())?.completed, 1);
    expect(store.progressFor(todayStamp())?.total, 1);
    expect(store.progressFor(todayStamp())?.isFull, isTrue);
    expect(store.progressFor(todayStamp())?.isPartial, isFalse);
  });

  List<HabitTask> recurringTasks() => const [
    HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
    HabitTask(
      id: 'homework',
      title: 'Домашнє завдання',
      points: 20,
      icon: 'homework',
      weekdays: [DateTime.saturday, DateTime.sunday],
    ),
    HabitTask(
      id: 'help',
      title: 'Допомогти',
      points: 8,
      icon: 'star',
      optional: true,
      weekdays: [DateTime.tuesday],
    ),
  ];

  test('recurring tasks only show on their days', () async {
    final monday = DateTime(2026, 8, 31);
    final store = testStore(now: () => monday, tasks: recurringTasks());
    await store.load();

    expect(store.dailyTasks.map((task) => task.id), ['bed', 'homework']);
    expect(store.todayDailyTasks.map((task) => task.id), ['bed']);
    expect(store.extraTasks, isEmpty);
    expect(store.pendingCount, 1);
    expect(store.todayPossiblePoints, 10);
    expect(store.todayEarnedPoints, 0);
    expect(store.progressFor('2026-08-31')?.total, 1);

    final tuesday = DateTime(2026, 9, 1);
    final tuesdayStore = testStore(now: () => tuesday, tasks: recurringTasks());
    await tuesdayStore.load();
    expect(tuesdayStore.todayDailyTasks.map((task) => task.id), ['bed']);
    expect(tuesdayStore.extraTasks.map((task) => task.id), ['help']);
    expect(tuesdayStore.extraPossiblePoints, 8);
    expect(tuesdayStore.todayPossiblePoints, 10);

    final saturday = DateTime(2026, 9, 5);
    final saturdayStore = testStore(
      now: () => saturday,
      tasks: recurringTasks(),
    );
    await saturdayStore.load();
    expect(saturdayStore.todayDailyTasks.map((task) => task.id), [
      'bed',
      'homework',
    ]);
    expect(saturdayStore.extraTasks, isEmpty);
    expect(saturdayStore.todayPossiblePoints, 30);
  });

  test('off-day tasks do not block the completion bonus', () async {
    final monday = DateTime(2026, 8, 31);
    final store = testStore(
      now: () => monday,
      tasks: const [
        HabitTask(id: 'teeth', title: 'Зуби', points: 10, icon: 'hygiene'),
        HabitTask(
          id: 'homework',
          title: 'Домашнє завдання',
          points: 20,
          icon: 'homework',
          weekdays: [DateTime.saturday, DateTime.sunday],
        ),
      ],
    );
    await store.load();

    await store.submit('teeth');
    expect(await store.verify('teeth'), 10);
    expect(store.totalPoints, 20);
    expect(store.progressFor('2026-08-31')?.isFull, isTrue);
  });

  test('streak counts consecutive full days and keeps today in progress', () {
    const history = DayHistory(
      days: {
        '2026-08-24': DayProgress(day: '2026-08-24', completed: 1, total: 1),
        '2026-08-25': DayProgress(day: '2026-08-25', completed: 1, total: 1),
        '2026-08-26': DayProgress(day: '2026-08-26', completed: 1, total: 1),
      },
    );
    expect(history.currentStreak('2026-08-26'), 3);
    expect(history.currentStreak('2026-08-27'), 3);
    expect(history.currentStreak('2026-08-28'), 0);
  });

  test('a missed day breaks the streak', () {
    const history = DayHistory(
      days: {
        '2026-08-24': DayProgress(day: '2026-08-24', completed: 1, total: 1),
        '2026-08-25': DayProgress(day: '2026-08-25', completed: 0, total: 1),
        '2026-08-26': DayProgress(day: '2026-08-26', completed: 1, total: 1),
      },
    );
    expect(history.currentStreak('2026-08-26'), 1);
  });

  test('streak walks across month boundaries', () {
    const history = DayHistory(
      days: {
        '2026-02-28': DayProgress(day: '2026-02-28', completed: 1, total: 1),
        '2026-03-01': DayProgress(day: '2026-03-01', completed: 1, total: 1),
      },
    );
    expect(history.currentStreak('2026-03-01'), 2);
  });

  test('verifying today grows the streak', () async {
    final clock = DateTime(2026, 8, 27);
    final store = testStore(
      now: () => clock,
      history: const DayHistory(
        activatedOn: '2026-08-25',
        days: {
          '2026-08-26': DayProgress(day: '2026-08-26', completed: 1, total: 1),
        },
      ),
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    expect(store.streak, 1);

    await store.submit('bed');
    await store.verify('bed');
    expect(store.streak, 2);
  });

  test('skipped days keep yesterday and fill the gap as pending', () async {
    final memory = <String, String>{};
    memory[LocalTaskRepository.legacyKey] = jsonEncode(
      TaskSnapshot(
        day: '2026-08-26',
        tasks: const [
          HabitTask(
            id: 'bed',
            title: 'Застелити ліжко',
            points: 10,
            icon: 'bed',
            status: TaskStatus.verified,
          ),
          HabitTask(
            id: 'help',
            title: 'Допомогти',
            points: 8,
            icon: 'star',
            optional: true,
            status: TaskStatus.verified,
          ),
        ],
      ).toJson(),
    );

    final repo = LocalTaskRepository(
      (key) async => memory[key],
      (key, value) async => memory[key] = value,
      now: () => DateTime(2026, 8, 28),
    );
    final loaded = await repo.loadToday();

    expect(loaded.current.day, '2026-08-28');
    expect(loaded.days.keys.toList()..sort(), [
      '2026-08-26',
      '2026-08-27',
      '2026-08-28',
    ]);
    expect(
      loaded.days['2026-08-26']!.tasks
          .singleWhere((t) => t.id == 'bed')
          .isVerified,
      isTrue,
    );
    expect(loaded.days['2026-08-27']!.tasks.map((task) => task.id), [
      'bed',
      'help',
    ]);
    expect(
      loaded.days['2026-08-27']!.tasks.every((task) => task.isPending),
      isTrue,
    );
    expect(loaded.current.tasks.every((task) => task.isPending), isTrue);
  });

  test('can complete a task from yesterday', () async {
    final clock = DateTime(2026, 8, 27);
    final store = HabitStore(
      pointsRepo: InMemoryPointsRepository(),
      taskRepo: InMemoryTaskRepository(
        const TaskSnapshot(
          day: '2026-08-27',
          tasks: [
            HabitTask(
              id: 'bed',
              title: 'Застелити ліжко',
              points: 10,
              icon: 'bed',
            ),
          ],
        ),
        days: {
          '2026-08-26': const TaskSnapshot(
            day: '2026-08-26',
            tasks: [
              HabitTask(
                id: 'bed',
                title: 'Застелити ліжко',
                points: 10,
                icon: 'bed',
              ),
              HabitTask(
                id: 'help',
                title: 'Допомогти',
                points: 8,
                icon: 'star',
                optional: true,
              ),
            ],
          ),
        },
      ),
      parentAuth: InMemoryParentAuth('mama'),
      gamePlays: InMemoryGamePlaysRepository(),
      goalRepo: InMemoryGoalRepository(),
      historyRepo: InMemoryDayHistoryRepository(
        const DayHistory(activatedOn: '2026-08-26'),
      ),
      celebrateFor: Duration.zero,
      now: () => clock,
    );
    await store.load();

    expect(store.canCompleteDay('2026-08-26'), isTrue);
    expect(store.tasksOn('2026-08-26'), hasLength(2));
    await store.submit('bed', day: '2026-08-26');
    await store.verify('bed', day: '2026-08-26');

    expect(store.totalPoints, 20);
    expect(store.tasksOn('2026-08-26').first.isVerified, isTrue);
    expect(store.tasks.single.isPending, isTrue);
    expect(store.progressFor('2026-08-26')?.completed, 1);
    expect(store.progressFor('2026-08-26')?.total, 1);
    expect(store.celebrating, isFalse);
  });

  test('a past day only shows tasks scheduled that day', () async {
    final clock = DateTime(2026, 9, 1);
    final store = HabitStore(
      pointsRepo: InMemoryPointsRepository(),
      taskRepo: InMemoryTaskRepository(
        const TaskSnapshot(
          day: '2026-09-01',
          tasks: [
            HabitTask(
              id: 'bed',
              title: 'Застелити ліжко',
              points: 10,
              icon: 'bed',
            ),
          ],
        ),
        days: {
          '2026-08-31': const TaskSnapshot(
            day: '2026-08-31',
            tasks: [
              HabitTask(
                id: 'bed',
                title: 'Застелити ліжко',
                points: 10,
                icon: 'bed',
              ),
              HabitTask(
                id: 'homework',
                title: 'Домашнє завдання',
                points: 20,
                icon: 'homework',
                weekdays: [DateTime.saturday, DateTime.sunday],
              ),
            ],
          ),
        },
      ),
      parentAuth: InMemoryParentAuth('mama'),
      gamePlays: InMemoryGamePlaysRepository(),
      goalRepo: InMemoryGoalRepository(),
      historyRepo: InMemoryDayHistoryRepository(),
      celebrateFor: Duration.zero,
      now: () => clock,
    );
    await store.load();

    expect(store.tasksOn('2026-08-31').map((task) => task.id), ['bed']);
    expect(store.progressFor('2026-08-31')?.total, 1);
    expect(store.progressFor('2026-08-31')?.completed, 0);
  });

  test('three strikes apply the penalty and stay until the next day', () async {
    var clock = DateTime(2026, 8, 29);
    final store = testStore(points: 25, now: () => clock);
    await store.load();

    var result = await store.addStrike();
    expect(result.penaltyHit, isFalse);
    expect(store.strikes, 1);
    expect(store.totalPoints, 25);
    expect(store.canStrike, isTrue);

    result = await store.addStrike();
    expect(result.penaltyHit, isFalse);
    expect(store.strikes, 2);
    expect(store.canStrike, isTrue);

    result = await store.addStrike();
    expect(result.penaltyHit, isTrue);
    expect(result.applied, -10);
    expect(store.strikes, 3);
    expect(store.canStrike, isFalse);
    expect(store.totalPoints, 15);

    result = await store.addStrike();
    expect(result.penaltyHit, isFalse);
    expect(store.strikes, 3);
    expect(store.totalPoints, 15);

    clock = DateTime(2026, 9, 1);
    await store.load();
    expect(store.strikes, 0);
    expect(store.canStrike, isTrue);
    expect(store.totalPoints, 15);
  });

  test(
    'strike penalty uses the parent amount and never goes below zero',
    () async {
      var clock = DateTime(2026, 8, 29);
      final store = testStore(points: 4, penaltyPoints: 20, now: () => clock);
      await store.load();
      expect(store.penaltyPoints, 20);

      await store.addStrike();
      await store.addStrike();
      final result = await store.addStrike();
      expect(result.penaltyHit, isTrue);
      expect(result.applied, -4);
      expect(store.totalPoints, 0);
      expect(store.strikes, 3);
    },
  );

  test('parent can change penalty points and clear strikes', () async {
    final store = testStore(points: 30, strikes: 2);
    await store.load();

    await store.setPenaltyPoints(7);
    expect(store.penaltyPoints, 7);
    await store.setPenaltyPoints(0);
    expect(store.penaltyPoints, 7);

    await store.clearStrikes();
    expect(store.strikes, 0);
  });

  test('backup round-trips strikes and penalty points', () async {
    final source = testStore(points: 40, strikes: 2, penaltyPoints: 15);
    await source.load();
    final snapshot = source.exportBackup();
    expect(snapshot.strikes, 2);
    expect(snapshot.penaltyPoints, 15);

    final encoded = snapshot.encode();
    final restored = BackupSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(restored.strikes, 2);
    expect(restored.penaltyPoints, 15);

    final old = BackupSnapshot.fromJson({
      'app': 'axo',
      'format': 1,
      'exportedAt': '2026-08-29T00:00:00.000Z',
      'data': {
        'points': 10,
        'onboardingComplete': true,
        'tasks': TaskSnapshot(day: todayStamp(), tasks: const []).toJson(),
        'goals': <dynamic>[],
        'history': const DayHistory().toJson(),
        'gamePlays': GamePlaysSnapshot.empty().toJson(),
      },
    });
    expect(old.strikes, 0);
    expect(old.penaltyPoints, AppConfig.defaultPenaltyPoints);

    final target = testStore(points: 1, strikes: 0, penaltyPoints: 10);
    await target.load();
    await target.importBackup(snapshot);
    expect(target.strikes, 2);
    expect(target.penaltyPoints, 15);
  });

  test('parents can add or take points, never below zero', () async {
    final store = testStore(points: 20);
    await store.load();

    expect(await store.adjustPoints(15), 15);
    expect(store.totalPoints, 35);
    expect(await store.adjustPoints(-40), -35);
    expect(store.totalPoints, 0);
    expect(await store.adjustPoints(-5), 0);
    expect(store.totalPoints, 0);
    expect(await store.adjustPoints(0), 0);
  });

  test('changing password requires the current one', () async {
    final store = testStore();
    await store.load();
    expect(await store.changePassword(current: 'nope', next: 'abcd'), isFalse);
    expect(store.checkPassword('4826'), isTrue);
    expect(await store.changePassword(current: '4826', next: 'abcd'), isTrue);
    expect(store.checkPassword('abcd'), isTrue);
  });

  test('a game round is ten items then complete', () {
    final round = GameRound();
    for (var i = 0; i < 7; i++) {
      round.record(true);
    }
    for (var i = 0; i < 3; i++) {
      round.record(false);
    }
    expect(round.correct, 7);
    expect(round.wrong, 3);
    expect(round.answered, AppConfig.roundLength);
    expect(round.isComplete, isTrue);
    round.reset();
    expect(round.answered, 0);
    expect(round.isComplete, isFalse);
  });

  test('games award points until the play limit', () async {
    final store = testStore();
    await store.load();

    for (var i = 0; i < AppConfig.rewardedPlays; i++) {
      expect(await store.tryAwardGamePlay('english'), 5);
    }
    expect(await store.tryAwardGamePlay('english'), 0);
    expect(store.totalPoints, AppConfig.rewardedPlays * 5);
    expect(store.playsUsed('english'), AppConfig.rewardedPlays);
    expect(store.playsLeft('english'), 0);
    expect(store.gamesLocked, isTrue);
    expect(await store.tryAwardGamePlay('spelling'), 0);
  });

  test('game rounds unlock again after the rest window', () async {
    var clock = DateTime(2026, 9, 1, 12);
    final store = testStore(now: () => clock);
    await store.load();

    expect(await store.tryAwardGamePlay('english'), 5);
    expect(await store.tryAwardGamePlay('spelling'), 5);
    expect(await store.tryAwardGamePlay('memory'), 5);
    expect(await store.tryAwardGamePlay('division'), 5);
    expect(await store.tryAwardGamePlay('simon'), 5);
    expect(store.windowLeft, 0);
    expect(store.gamesLocked, isTrue);

    clock = clock.add(const Duration(minutes: 14));
    expect(store.windowLeft, 0);

    clock = clock.add(const Duration(minutes: 1));
    expect(store.windowLeft, AppConfig.rewardedPlays);
    expect(store.gamesLocked, isFalse);
    expect(await store.tryAwardGamePlay('english'), 5);
  });

  test('cooldown only starts if the rounds fall in the rest window', () async {
    var clock = DateTime(2026, 9, 1, 12);
    final store = testStore(now: () => clock);
    await store.load();

    expect(await store.tryAwardGamePlay('english'), 5);
    expect(store.gamesLocked, isFalse);

    clock = clock.add(AppConfig.playLimitWindow);
    expect(await store.tryAwardGamePlay('spelling'), 5);
    expect(await store.tryAwardGamePlay('memory'), 5);
    expect(store.gamesLocked, isFalse);
    expect(store.windowUsed, 2);
  });

  test('a full rest window starts after clustered rounds', () async {
    var clock = DateTime(2026, 9, 1, 12);
    final store = testStore(now: () => clock);
    await store.load();

    expect(await store.tryAwardGamePlay('english'), 5);
    clock = clock.add(const Duration(minutes: 3));
    expect(await store.tryAwardGamePlay('spelling'), 5);
    clock = clock.add(const Duration(minutes: 3));
    expect(await store.tryAwardGamePlay('memory'), 5);
    clock = clock.add(const Duration(minutes: 3));
    expect(await store.tryAwardGamePlay('division'), 5);
    clock = clock.add(const Duration(minutes: 3));
    expect(await store.tryAwardGamePlay('simon'), 5);
    expect(store.gamesLocked, isTrue);
    expect(store.playsCooldown, AppConfig.playLimitWindow);

    clock = clock.add(const Duration(minutes: 14));
    expect(store.gamesLocked, isTrue);

    clock = clock.add(const Duration(minutes: 1));
    expect(store.gamesLocked, isFalse);
  });

  test('per-game point caps stay after the cooldown', () async {
    var clock = DateTime(2026, 9, 1, 12);
    final store = testStore(now: () => clock);
    await store.load();

    for (var i = 0; i < AppConfig.rewardedPlays; i++) {
      expect(await store.tryAwardGamePlay('english'), 5);
    }
    expect(store.playsUsed('english'), AppConfig.rewardedPlays);
    expect(store.playsUsed('spelling'), 0);
    expect(store.gamesLocked, isTrue);

    clock = clock.add(AppConfig.playLimitWindow);
    expect(store.gamesLocked, isFalse);
    expect(store.playsUsed('english'), AppConfig.rewardedPlays);
    expect(await store.tryAwardGamePlay('english'), 0);
    expect(await store.tryAwardGamePlay('spelling'), 5);
    expect(store.playsUsed('spelling'), 1);
    expect(store.playsUsed('english'), AppConfig.rewardedPlays);
  });

  test('parent can change play rounds and rest time', () async {
    var clock = DateTime(2026, 9, 1, 12);
    final store = testStore(now: () => clock);
    await store.load();
    expect(store.rewardedPlays, 5);
    expect(store.playLimitMinutes, 15);

    await store.setGameLimit(rounds: 3, restMinutes: 30);
    expect(store.rewardedPlays, 3);
    expect(store.playLimitMinutes, 30);
    expect(store.playLimitWindow, const Duration(minutes: 30));

    await store.setGameLimit(rounds: 0, restMinutes: 1);
    expect(store.rewardedPlays, 3);
    expect(store.playLimitMinutes, 30);

    expect(await store.tryAwardGamePlay('english'), 5);
    expect(await store.tryAwardGamePlay('spelling'), 5);
    expect(await store.tryAwardGamePlay('memory'), 5);
    expect(store.gamesLocked, isTrue);
    expect(store.playsCooldown, const Duration(minutes: 30));
  });

  test('backup round-trips game limit settings', () async {
    final source = testStore(rewardedPlays: 3, playLimitMinutes: 30);
    await source.load();
    final snapshot = source.exportBackup();
    expect(snapshot.rewardedPlays, 3);
    expect(snapshot.playLimitMinutes, 30);

    final encoded = snapshot.encode();
    final restored = BackupSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(restored.rewardedPlays, 3);
    expect(restored.playLimitMinutes, 30);

    final old = BackupSnapshot.fromJson({
      'app': 'axo',
      'format': 1,
      'exportedAt': '2026-08-29T00:00:00.000Z',
      'data': {
        'points': 10,
        'onboardingComplete': true,
        'tasks': TaskSnapshot(day: todayStamp(), tasks: const []).toJson(),
        'goals': <dynamic>[],
        'history': const DayHistory().toJson(),
        'gamePlays': GamePlaysSnapshot.empty().toJson(),
      },
    });
    expect(old.rewardedPlays, AppConfig.rewardedPlays);
    expect(old.playLimitMinutes, AppConfig.playLimitMinutes);

    final target = testStore(rewardedPlays: 8, playLimitMinutes: 45);
    await target.load();
    await target.importBackup(snapshot);
    expect(target.rewardedPlays, 3);
    expect(target.playLimitMinutes, 30);
  });

  test('backup round-trips completion bonus settings', () async {
    final source = testStore(
      completionBonusEnabled: false,
      completionBonusPoints: 15,
    );
    await source.load();
    final snapshot = source.exportBackup();
    expect(snapshot.completionBonusEnabled, isFalse);
    expect(snapshot.completionBonusPoints, 15);

    final encoded = snapshot.encode();
    final restored = BackupSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(restored.completionBonusEnabled, isFalse);
    expect(restored.completionBonusPoints, 15);

    final old = BackupSnapshot.fromJson({
      'app': 'axo',
      'format': 1,
      'exportedAt': '2026-08-29T00:00:00.000Z',
      'data': {
        'points': 10,
        'onboardingComplete': true,
        'tasks': TaskSnapshot(day: todayStamp(), tasks: const []).toJson(),
        'goals': <dynamic>[],
        'history': const DayHistory().toJson(),
        'gamePlays': GamePlaysSnapshot.empty().toJson(),
      },
    });
    expect(old.completionBonusEnabled, AppConfig.defaultCompletionBonusEnabled);
    expect(old.completionBonusPoints, AppConfig.defaultCompletionBonusPoints);

    final target = testStore(
      completionBonusEnabled: true,
      completionBonusPoints: 40,
    );
    await target.load();
    await target.importBackup(snapshot);
    expect(target.completionBonusEnabled, isFalse);
    expect(target.completionBonusPoints, 15);
  });

  test('old daily play counts start a fresh window', () {
    final snapshot = GamePlaysSnapshot.fromJson({
      'day': '2026-08-29',
      'counts': {'english': 3},
    });
    expect(snapshot.rounds, isEmpty);
  });

  test('game rounds award different points by mode', () async {
    final store = testStore();
    await store.load();

    expect(await store.tryAwardGamePlay('times_tables', points: 1), 1);
    expect(store.totalPoints, 1);
    expect(await store.tryAwardGamePlay('times_tables', points: 3), 3);
    expect(await store.tryAwardGamePlay('times_tables', points: 5), 5);
    expect(await store.tryAwardGamePlay('times_tables', points: 5), 5);
    expect(await store.tryAwardGamePlay('times_tables', points: 5), 5);
    expect(await store.tryAwardGamePlay('times_tables', points: 5), 0);
    expect(store.totalPoints, 19);
  });

  testWidgets('game banner counts scored rounds as used out of the limit', (
    tester,
  ) async {
    var clock = DateTime(2026, 9, 1, 12);
    final store = testStore(now: () => clock);
    await store.load();

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(body: GamePlaysBanner(gameId: 'english')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Раунди зараз'), findsOneWidget);
    expect(find.text('0/${AppConfig.rewardedPlays}'), findsOneWidget);

    expect(await store.tryAwardGamePlay('spelling'), 5);
    await tester.pump();
    expect(find.text('0/${AppConfig.rewardedPlays}'), findsOneWidget);

    expect(await store.tryAwardGamePlay('english'), 5);
    await tester.pump();
    expect(find.text('1/${AppConfig.rewardedPlays}'), findsOneWidget);
  });

  testWidgets('game setup shows point rounds then training after the cap', (
    tester,
  ) async {
    var clock = DateTime(2026, 9, 1, 12);
    final store = testStore(now: () => clock);
    await store.load();

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: GameSetupBody(gameId: 'english', onStart: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0/${AppConfig.rewardedPlays}'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    for (var i = 0; i < AppConfig.rewardedPlays; i++) {
      expect(await store.tryAwardGamePlay('english'), 5);
    }
    await tester.pump();
    expect(
      find.text(S.gamePointsGone(AppConfig.rewardedPlays)),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    clock = clock.add(AppConfig.playLimitWindow);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(S.practiceMode), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  test('home recents fill from the catalog then last played', () {
    expect(pickRecentMiniGames(const []).map((game) => game.id), [
      AppConfig.timesTablesGame,
      AppConfig.spellingGame,
    ]);
    expect(
      pickRecentMiniGames(const [AppConfig.englishGame]).map((game) => game.id),
      [AppConfig.englishGame, AppConfig.timesTablesGame],
    );
    expect(
      pickRecentMiniGames(const [AppConfig.englishGame, AppConfig.spellingGame])
          .map((game) => game.id),
      [AppConfig.englishGame, AppConfig.spellingGame],
    );
  });

  test('last played games stay first after a reload', () async {
    final recents = InMemoryGameRecentsRepository();
    final store = testStore(gameRecents: recents);
    await store.load();
    await store.markGamePlayed(AppConfig.englishGame);
    await store.markGamePlayed(AppConfig.spellingGame);
    expect(store.recentGameIds, [
      AppConfig.spellingGame,
      AppConfig.englishGame,
    ]);

    final reopened = testStore(gameRecents: recents);
    await reopened.load();
    expect(reopened.recentGameIds, [
      AppConfig.spellingGame,
      AppConfig.englishGame,
    ]);
  });

  testWidgets('home shows two games and opens the full list', (tester) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('all-games')),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text(S.timesTables), findsOneWidget);
    expect(find.text(S.spelling), findsOneWidget);
    expect(find.text(S.english), findsNothing);

    await tester.tap(find.byKey(const Key('all-games')));
    await tester.pumpAndSettle();

    expect(find.byType(GamesScreen), findsOneWidget);
    expect(find.text(S.english), findsOneWidget);
    expect(find.text(S.division), findsOneWidget);
    expect(find.text(S.memory), findsOneWidget);
    expect(find.text(S.simon), findsOneWidget);
  });

  testWidgets('a recently played game replaces a card on home', (tester) async {
    final store = testStore();
    await store.load();
    await store.markGamePlayed(AppConfig.englishGame);
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('all-games')),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text(S.english), findsOneWidget);
    expect(find.text(S.timesTables), findsOneWidget);
    expect(find.text(S.spelling), findsNothing);
  });

  test('a math round does not repeat a problem', () {
    final times = ShuffledDeck(
      items: TimesTablesProblem.all(1, 5),
      random: Random(1),
    );
    final timesRound = [for (var i = 0; i < 10; i++) times.next()];
    expect(timesRound.toSet(), hasLength(10));

    final divisions = ShuffledDeck(
      items: DivisionProblem.all(1, 5),
      random: Random(2),
    );
    final divisionRound = [for (var i = 0; i < 10; i++) divisions.next()];
    expect(divisionRound.toSet(), hasLength(10));
  });

  test('math decks reshuffle without repeating the last problem', () {
    final all = TimesTablesProblem.all(6, 10);
    expect(all, hasLength(25));
    final deck = ShuffledDeck(items: all, random: Random(3));
    final first = [for (var i = 0; i < all.length; i++) deck.next()];
    expect(first.toSet(), hasLength(all.length));
    expect(deck.next(), isNot(first.last));
  });

  test('division problems always divide evenly', () {
    final random = Random(1);
    for (var i = 0; i < 200; i++) {
      final problem = DivisionProblem.generate(random, 1, 10);
      expect(problem.divisor, greaterThan(0));
      expect(problem.dividend, problem.divisor * problem.answer);
      expect(problem.answer, inInclusiveRange(1, 10));
    }
  });

  test('memory deck deals matching pairs', () {
    final tiles = MemoryDeck.deal(Random(2), pairs: AppConfig.memoryPairs);
    expect(tiles, hasLength(16));
    final counts = <int, int>{};
    for (final tile in tiles) {
      counts[tile.faceIndex] = (counts[tile.faceIndex] ?? 0) + 1;
    }
    expect(counts.length, 8);
    expect(counts.values.every((n) => n == 2), isTrue);
  });

  testWidgets('home keeps the last two played games', (tester) async {
    final store = testStore();
    await store.load();
    await store.markGamePlayed(AppConfig.divisionGame);
    await store.markGamePlayed(AppConfig.memoryGame);
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('all-games')),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text(S.memory), findsOneWidget);
    expect(find.text(S.division), findsOneWidget);
    expect(find.text(S.timesTables), findsNothing);
    expect(find.text(S.spelling), findsNothing);
  });

  testWidgets('division round shows an even problem', (tester) async {
    final store = testStore();
    await store.load();
    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: DivisionScreen(random: Random(1)),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(S.letsGo));
    await tester.pump();

    expect(find.textContaining('÷'), findsOneWidget);
  });

  testWidgets('memory match stays open and mismatch flips back', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: MemoryScreen(
            pairs: 2,
            mismatchHold: Duration.zero,
            tiles: [
              MemoryTile(id: 0, faceIndex: 0),
              MemoryTile(id: 1, faceIndex: 1),
              MemoryTile(id: 2, faceIndex: 0),
              MemoryTile(id: 3, faceIndex: 1),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(S.letsGo));
    await tester.pump();

    Finder boardIcon(IconData icon) => find.descendant(
      of: find.byKey(const Key('memory-board')),
      matching: find.byIcon(icon),
    );

    expect(boardIcon(Icons.pets_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('memory-0')));
    await tester.pump();
    expect(boardIcon(Icons.pets_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('memory-1')));
    await tester.pumpAndSettle();
    expect(boardIcon(Icons.pets_rounded), findsNothing);
    expect(boardIcon(Icons.star_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('memory-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('memory-2')));
    await tester.pump();
    expect(boardIcon(Icons.pets_rounded), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('memory-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('memory-3')));
    await tester.pump();
    await tester.pump();

    expect(store.playsUsed(AppConfig.memoryGame), 1);
    expect(store.totalPoints, AppConfig.memoryRoundPoints);
    expect(find.text(S.correct), findsOneWidget);
    expect(find.text(S.wrongCount), findsNothing);
  });

  test('simon sequence stays in range and grows by one', () {
    final random = Random(1);
    final first = SimonSequence.ofLength(2, random, pads: 4);
    expect(first, hasLength(2));
    expect(first.every((i) => i >= 0 && i < 4), isTrue);
    final grown = SimonSequence.grow(first, random, pads: 4);
    expect(grown, hasLength(3));
    expect(grown.sublist(0, 2), first);
    expect(grown.last, inInclusiveRange(0, 3));
  });

  testWidgets('simon repeats the sequence and awards a round', (tester) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: SimonScreen(
            startLength: 1,
            turns: 1,
            sequence: const [0],
            stepHold: Duration.zero,
            gapHold: Duration.zero,
            missHold: Duration.zero,
            tapHold: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(S.letsGo));
    await tester.pump();

    expect(find.byKey(const Key('simon-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('simon-0')));
    await tester.pump();

    expect(store.playsUsed(AppConfig.simonGame), 1);
    expect(store.totalPoints, AppConfig.simonRoundPoints);
    expect(find.text(S.roundDone), findsOneWidget);
    expect(find.text(S.correctCount), findsOneWidget);
  });

  testWidgets('simon counts a miss and still finishes the round', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: SimonScreen(
            startLength: 1,
            turns: 1,
            sequence: const [0],
            stepHold: Duration.zero,
            gapHold: Duration.zero,
            missHold: Duration.zero,
            tapHold: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(S.letsGo));
    await tester.pump();

    await tester.tap(find.byKey(const Key('simon-1')));
    await tester.pump();

    expect(store.playsUsed(AppConfig.simonGame), 1);
    expect(store.totalPoints, AppConfig.simonRoundPoints);
    expect(find.text(S.roundDone), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('simon cheers before the next sequence', (tester) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: SimonScreen(
            startLength: 1,
            turns: 2,
            sequence: const [0],
            stepHold: Duration.zero,
            gapHold: Duration.zero,
            missHold: Duration.zero,
            tapHold: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(S.letsGo));
    await tester.pump();
    await tester.tap(find.byKey(const Key('simon-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(S.correct), findsOneWidget);
    expect(find.text(S.roundDone), findsNothing);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
  });

  testWidgets('simon keeps going after a miss before the next sequence', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: SimonScreen(
            startLength: 1,
            turns: 2,
            sequence: const [0],
            stepHold: Duration.zero,
            gapHold: Duration.zero,
            missHold: Duration.zero,
            tapHold: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(S.letsGo));
    await tester.pump();
    await tester.tap(find.byKey(const Key('simon-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(S.keepGoing), findsOneWidget);
    expect(find.text(S.roundDone), findsNothing);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
  });

  testWidgets('simon fills a pad only briefly after a tap', (tester) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Color padColor() {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('simon-0')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: SimonScreen(
            startLength: 2,
            turns: 1,
            sequence: const [0, 0],
            stepHold: Duration.zero,
            gapHold: Duration.zero,
            missHold: Duration.zero,
            tapHold: const Duration(milliseconds: 200),
            flashHold: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(S.letsGo));
    await tester.pump();

    expect(padColor(), Colors.white);

    await tester.tap(find.byKey(const Key('simon-0')));
    await tester.pump();
    expect(padColor(), AppColors.pinkDark);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(padColor(), Colors.white);

    await tester.tap(find.byKey(const Key('simon-0')));
    await tester.pump();
    expect(padColor(), AppColors.pinkDark);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text(S.roundDone), findsOneWidget);
  });

  testWidgets('parent settings lists daily tasks', (tester) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Щоденні завдання'), findsOneWidget);
    expect(find.text(S.dailyTasksHint), findsOneWidget);
    expect(find.text('Застелити ліжко'), findsNothing);
    expect(find.text('Щоденні додаткові завдання'), findsOneWidget);
    expect(find.text(S.dailyOptionalTasksHint), findsOneWidget);
    expect(find.text('Цілі'), findsOneWidget);
    expect(find.text(S.goalsHint), findsOneWidget);
    expect(find.text('Бонус і штраф'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Резервна копія'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Резервна копія'), findsOneWidget);
    expect(find.text('Експорт і імпорт'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Змінити пароль'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Змінити пароль'), findsOneWidget);
    expect(find.text(S.privacy), findsOneWidget);
    expect(find.byKey(const Key('export-backup')), findsNothing);
    expect(find.byKey(const Key('import-backup')), findsNothing);
    expect(
      find.text('Імпорт замінить усі дані на цьому телефоні.'),
      findsNothing,
    );

    await openParentSetting(tester, const Key('settings-backup'));
    expect(find.byKey(const Key('export-backup')), findsOneWidget);
    expect(find.byKey(const Key('import-backup')), findsOneWidget);
    expect(find.text('Експортувати'), findsOneWidget);
    expect(find.text('Імпортувати'), findsOneWidget);
  });

  testWidgets('import replace dialog warns that data will be replaced', (
    tester,
  ) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await openParentSetting(tester, const Key('settings-backup'));

    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pumpAndSettle();
    expect(find.text(S.importReplaceTitle), findsOneWidget);
    expect(find.text(S.importReplaceBody), findsOneWidget);

    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(find.text(S.importReplaceTitle), findsNothing);

    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pumpAndSettle();
    expect(find.text(S.importReplaceTitle), findsOneWidget);
    expect(find.text(S.importReplaceBody), findsOneWidget);
  });

  testWidgets('parent settings hides today-only tasks', (tester) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
        HabitTask(
          id: 'park',
          title: 'Прогулянка',
          points: 15,
          icon: 'walk',
          todayOnly: true,
        ),
      ],
    );
    await store.load();

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Застелити ліжко'), findsNothing);
    expect(find.text('Щоденні додаткові завдання'), findsOneWidget);
    expect(find.text('Прогулянка'), findsNothing);

    await openParentSetting(tester, const Key('settings-daily-tasks'));
    expect(find.text('Застелити ліжко'), findsOneWidget);
    expect(find.text('Прогулянка'), findsNothing);
  });

  testWidgets('parent settings can add a daily optional task', (tester) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    await openParentSetting(tester, const Key('settings-daily-optional-tasks'));
    await tester.tap(find.byKey(const Key('add-daily-optional-task')));
    await tester.pumpAndSettle();

    expect(find.text('Додати завдання'), findsOneWidget);
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
      'Допомогти вдома',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Зберегти'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Допомогти вдома'), findsWidgets);
    expect(store.dailyOptionalTasks, hasLength(1));
    expect(store.dailyOptionalTasks.single.title, 'Допомогти вдома');
    expect(store.dailyOptionalTasks.single.optional, isTrue);
    expect(store.dailyOptionalTasks.single.todayOnly, isFalse);
    expect(store.dailyTasks, hasLength(1));
  });

  testWidgets('parent settings can add and remove points', (tester) async {
    final store = testStore(points: 20);
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    await openParentSetting(tester, const Key('settings-bonus-points'));
    expect(find.text('Зараз 20 балів'), findsOneWidget);
    expect(find.text('+10'), findsNothing);

    await tester.enterText(find.byKey(const Key('bonus-amount')), '12ab-3.5');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('bonus-amount')),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      '1235',
    );

    await tester.enterText(find.byKey(const Key('bonus-amount')), '10');
    await tester.pump();
    await tester.tap(find.text('Додати'));
    await tester.pump();
    expect(store.totalPoints, 30);
    expect(find.text('Зараз 30 балів'), findsOneWidget);
    expect(find.text('Нараховано 10 балів'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('bonus-amount')), '15');
    await tester.pump();
    await tester.tap(find.text('Зняти'));
    await tester.pump();
    expect(store.totalPoints, 15);
    expect(find.text('Зараз 15 балів'), findsOneWidget);
  });

  testWidgets('parent settings lists goals and can spend them', (tester) async {
    final store = testStore(
      points: 80,
      goals: const [
        RewardGoal(id: 'ice', title: 'Морозиво', cost: 50, icon: 'gift'),
      ],
    );
    await store.load();

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    await openParentSetting(tester, const Key('settings-goals'));
    expect(find.text('Морозиво'), findsWidgets);
    expect(find.text('80 балів / 50 балів'), findsOneWidget);
    await tester.tap(find.text('Видати'));
    await tester.pumpAndSettle();

    expect(find.text(S.spendGoalTitle), findsOneWidget);
    expect(find.text('Видати «Морозиво» і списати бали?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );
    expect(store.totalPoints, 80);

    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(find.text(S.spendGoalTitle), findsNothing);
    expect(store.totalPoints, 80);

    await tester.tap(find.text('Видати'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Видати'),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.totalPoints, 30);
    expect(store.activeGoals, isEmpty);
    expect(store.completedGoals.single.id, 'ice');
    expect(find.text('Ціль отримано!'), findsOneWidget);
    expect(
      find.text('Поки немає цілей — додайте щось смачненьке.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('completed-goals')));
    await tester.pumpAndSettle();
    expect(find.text('Видані цілі'), findsOneWidget);
    expect(find.text('Морозиво'), findsOneWidget);
  });

  testWidgets('task editor keeps delete away from cancel', (tester) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await openParentSetting(tester, const Key('settings-daily-tasks'));
    await tester.tap(find.text('Застелити ліжко').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Змінити завдання'), findsOneWidget);
    expect(find.text('Назва'), findsOneWidget);
    expect(find.text('Видалити'), findsNothing);

    final delete = tester.getTopLeft(find.byIcon(Icons.delete_outline_rounded));
    final cancel = tester.getTopLeft(find.text('Скасувати'));
    expect(delete.dy, lessThan(cancel.dy));

    final dialog = tester.getSize(find.byType(AlertDialog));
    await tester.enterText(find.byType(TextField).first, 'Нова назва завдання');
    await tester.pump();
    expect(tester.getSize(find.byType(AlertDialog)), dialog);
  });

  testWidgets('task editor can set recurring days', (tester) async {
    final monday = DateTime(2026, 8, 31);
    final store = testStore(now: () => monday);
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Color chipColor(int weekday) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(Key('task-day-$weekday')),
            matching: find.byType(Text),
          ),
        )
        .style!
        .color!;

    await pumpParentSettings(tester, store);
    await openParentSetting(tester, const Key('settings-daily-optional-tasks'));
    await tester.tap(find.byKey(const Key('add-daily-optional-task')));
    await tester.pumpAndSettle();

    expect(find.text(S.taskDays), findsOneWidget);
    expect(chipColor(DateTime.monday), AppColors.pinkDark);
    expect(chipColor(DateTime.sunday), AppColors.pinkDark);

    await tester.tap(find.byKey(const Key('task-day-6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task-day-7')));
    await tester.pump();
    expect(chipColor(DateTime.saturday), AppColors.muted);
    expect(chipColor(DateTime.sunday), AppColors.muted);

    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
      'Допомогти вдома',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Зберегти'),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.dailyOptionalTasks.single.title, 'Допомогти вдома');
    expect(store.dailyOptionalTasks.single.weekdays, [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ]);
    expect(store.extraTasks.single.title, 'Допомогти вдома');

    await tester.tap(find.text('Допомогти вдома').hitTestable());
    await tester.pumpAndSettle();
    expect(chipColor(DateTime.saturday), AppColors.muted);
    expect(chipColor(DateTime.monday), AppColors.pinkDark);

    await tester.tap(find.byKey(const Key('task-day-6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task-day-7')));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Зберегти'),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.dailyOptionalTasks.single.weekdays, isEmpty);
    expect(store.extraTasks.single.title, 'Допомогти вдома');
  });

  testWidgets('task editor shows recurring days for today-only tasks', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('add-today-task')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('add-today-task')));
    await tester.pump();

    expect(
      find.text('Введи пароль, щоб додати завдання на сьогодні'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Додати завдання'), findsOneWidget);
    expect(find.text(S.taskDays), findsOneWidget);
    expect(find.byKey(const Key('task-day-1')), findsOneWidget);
    expect(find.byKey(const Key('task-day-7')), findsOneWidget);
  });

  testWidgets('home can add a daily task after parent approval', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    await tester.tap(find.byKey(const Key('add-daily-task')));
    await tester.pump();
    expect(find.text(S.addDailyTaskPrompt), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();

    expect(find.text(S.addTask), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Полити квіти');
    await tester.tap(find.text('Зберегти'));
    await tester.pump();
    await tester.pump();

    expect(store.dailyTasks.single.title, 'Полити квіти');
    expect(store.todayDailyTasks.single.title, 'Полити квіти');
    expect(find.text('Полити квіти'), findsOneWidget);
  });

  testWidgets('first launch walks parents through setup once', (tester) async {
    final store = testStore(password: null);
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    expect(find.text('Привіт! Я Аксо.'), findsOneWidget);
    expect(
      find.text(
        'Цей розділ — для мами і тата. Тут ви налаштуєте додаток, перш ніж віддати телефон дитині.',
      ),
      findsOneWidget,
    );
    expect(store.needsOnboarding, isTrue);

    await tester.tap(find.text('Далі'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'mama');
    await tester.enterText(find.byType(TextField).at(1), 'mama');
    await tester.tap(find.text('Далі'));
    await tester.pump();

    expect(find.text('За що збираємо бали?'), findsOneWidget);
    expect(store.parentPassword, isNull);

    await tester.tap(find.byKey(const Key('onboarding-add-goal')));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Морозиво');
    await tester.tap(find.text('Зберегти'));
    await tester.pump();
    expect(find.text('Морозиво'), findsOneWidget);

    await tester.tap(find.text('Далі'));
    await tester.pump();
    expect(find.text('Усе готово!'), findsOneWidget);
    expect(
      find.text(
        'Налаштування завершено. Далі Аксо — для дитини: завдання, ігри й цілі. Мама й тато підтверджують виконане паролем.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Зрозуміло'));
    await tester.pump();

    expect(store.parentPassword, 'mama');
    expect(store.totalPoints, 50);
    expect(store.onboardingComplete, isTrue);
    expect(store.needsOnboarding, isFalse);
    expect(store.goals.single.title, 'Морозиво');
    expect(store.history.activatedOn, todayStamp());
    expect(find.text('Завдання на сьогодні'), findsOneWidget);
    expect(find.text('Морозиво'), findsOneWidget);
  });

  testWidgets('home shows a streak badge after consecutive full days', (
    tester,
  ) async {
    final clock = DateTime(2026, 8, 27);
    final store = testStore(
      now: () => clock,
      history: const DayHistory(
        activatedOn: '2026-08-25',
        days: {
          '2026-08-26': DayProgress(day: '2026-08-26', completed: 1, total: 1),
        },
      ),
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    expect(find.byKey(const Key('streak-badge')), findsOneWidget);
    expect(find.text('1 день поспіль'), findsOneWidget);
  });

  testWidgets('home hides the streak badge when there is no streak', (
    tester,
  ) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    expect(find.byKey(const Key('streak-badge')), findsNothing);
  });

  testWidgets('home calendar shows the current month', (tester) async {
    final store = testStore(
      tasks: const [
        HabitTask(
          id: 'bed',
          title: 'Застелити ліжко',
          points: 10,
          icon: 'bed',
          status: TaskStatus.verified,
        ),
      ],
    );
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    final now = DateTime.now();
    await tester.scrollUntilVisible(
      find.text(S.monthTitle(now.year, now.month)),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text(S.monthTitle(now.year, now.month)), findsOneWidget);
    expect(find.text('Усі завдання'), findsOneWidget);
    expect(find.text('Частина'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
  });

  testWidgets('calendar opens yesterday so a missed task can be completed', (
    tester,
  ) async {
    final clock = DateTime(2026, 8, 27);
    final store = HabitStore(
      pointsRepo: InMemoryPointsRepository(),
      taskRepo: InMemoryTaskRepository(
        const TaskSnapshot(
          day: '2026-08-27',
          tasks: [
            HabitTask(
              id: 'bed',
              title: 'Застелити ліжко',
              points: 10,
              icon: 'bed',
            ),
          ],
        ),
        days: {
          '2026-08-26': const TaskSnapshot(
            day: '2026-08-26',
            tasks: [
              HabitTask(
                id: 'teeth',
                title: 'Почистити зуби',
                points: 10,
                icon: 'hygiene',
              ),
            ],
          ),
        },
      ),
      parentAuth: InMemoryParentAuth('4826'),
      gamePlays: InMemoryGamePlaysRepository(),
      goalRepo: InMemoryGoalRepository(),
      historyRepo: InMemoryDayHistoryRepository(
        const DayHistory(activatedOn: '2026-08-26'),
      ),
      celebrateFor: Duration.zero,
      now: () => clock,
    );
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('cal-2026-08-26')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.byKey(const Key('cal-2026-08-26')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cal-2026-08-26')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(S.tasksForDay('2026-08-26')), findsOneWidget);
    expect(find.text('Почистити зуби'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('day-tasks-2026-08-26')),
        matching: find.text(S.done),
      ),
    );
    await tester.pump();
    expect(store.tasksOn('2026-08-26').single.isSubmitted, isTrue);
  });

  testWidgets('home shows goal progress until it can be spent', (tester) async {
    final store = testStore(
      points: 20,
      goals: const [
        RewardGoal(id: 'ice', title: 'Морозиво', cost: 50, icon: 'gift'),
      ],
    );
    await store.load();

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    expect(find.text('Цілі'), findsOneWidget);
    expect(find.text('Морозиво'), findsOneWidget);
    expect(find.text('20 балів / 50 балів'), findsOneWidget);
    expect(find.text('Ще 30 балів'), findsOneWidget);
    expect(find.text('Можна отримати!'), findsNothing);

    await store.pointsRepo.setTotal(50);
    store.totalPoints = 50;
    store.notifyListeners();
    await tester.pump();
    expect(find.text('50 балів / 50 балів'), findsOneWidget);
    expect(find.text('Можна отримати!'), findsOneWidget);

    await tester.tap(find.text('Морозиво'));
    await tester.pump();
    expect(find.text('Видати цю ціль і списати бали?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();

    expect(store.totalPoints, 0);
    expect(store.activeGoals, isEmpty);
    expect(store.completedGoals.single.id, 'ice');
    expect(find.text('Морозиво'), findsNothing);
  });

  testWidgets('home shows points and todays tasks', (tester) async {
    final store = testStore(
      points: 42,
      tasks: const [
        HabitTask(
          id: 'teeth',
          title: 'Почистити зуби',
          points: 10,
          icon: 'hygiene',
        ),
      ],
    );
    await store.load();

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Почистити зуби'), findsOneWidget);
    expect(find.text('Завдання на сьогодні'), findsOneWidget);
    expect(find.text('0 / 10 балів'), findsOneWidget);

    final bubbleSize = tester.getSize(find.byType(SpeechBubble));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('Зробив!'));
    await tester.pump();
    expect(find.text('Чекає маму чи тата'), findsOneWidget);
    expect(store.totalPoints, 42);
    expect(tester.getSize(find.byType(SpeechBubble)), bubbleSize);

    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити').last);
    await tester.pump();
    await tester.tap(find.text('Нарахувати бали'));
    await tester.pump();
    await tester.pump();
    expect(store.totalPoints, 62);
    expect(find.byKey(const Key('completion-bonus-dialog')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('completion-bonus-dialog')),
        matching: find.text('+10 балів'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('completion-bonus-ok')));
    await tester.pump();
    expect(find.text('Підтверджено'), findsOneWidget);
    expect(find.text('10 / 10 балів'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Множення'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Множення'), findsOneWidget);
    expect(find.text('Правопис'), findsOneWidget);
    expect(find.text('Англійська'), findsNothing);
    expect(find.byKey(const Key('all-games')), findsOneWidget);
  });

  testWidgets('home points label opens bonus screen after parent password', (
    tester,
  ) async {
    final store = testStore(points: 42);
    await store.load();

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    await tester.tap(find.byKey(const Key('points-label')));
    await tester.pump();
    expect(
      find.text('Введи пароль, щоб нарахувати або зняти бали'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Бонус і штраф'), findsOneWidget);
    expect(find.text('Зараз 42 бали'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('bonus-amount')), '8');
    await tester.pump();
    await tester.tap(find.text('Додати'));
    await tester.pump();
    expect(store.totalPoints, 50);
    expect(find.text('Нараховано 8 балів'), findsAtLeastNWidgets(1));
  });

  testWidgets('home shows strikes and parent can add one after password', (
    tester,
  ) async {
    final store = testStore(points: 30);
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-strike')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.byKey(const Key('add-strike')));
    await tester.pump();
    expect(find.text('Страйки'), findsOneWidget);
    expect(find.text('0 з 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-strike')));
    await tester.pump();
    expect(find.text('Введи пароль, щоб дати страйк'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();

    expect(store.strikes, 1);
    expect(find.text('1 з 3'), findsOneWidget);
    expect(find.text('Страйк 1 з 3'), findsAtLeastNWidgets(1));
  });

  testWidgets('third home strike applies the penalty', (tester) async {
    final store = testStore(points: 30, strikes: 2);
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('add-strike')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.byKey(const Key('add-strike')));
    await tester.pump();
    expect(find.text('2 з 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-strike')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Третій страйк'), findsOneWidget);
    expect(
      find.text('Це зніме 10 балів у дитини. Продовжити?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Скасувати'));
    await tester.pump();
    expect(store.strikes, 2);
    expect(store.totalPoints, 30);

    await tester.tap(find.byKey(const Key('add-strike')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Продовжити'));
    await tester.pump();
    await tester.pump();

    expect(store.strikes, 3);
    expect(store.totalPoints, 20);
    expect(find.text('3 з 3'), findsOneWidget);
    expect(find.text('Три страйки! Знято 10 балів'), findsAtLeastNWidgets(1));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('add-strike')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('parent settings can change penalty amount and clear strikes', (
    tester,
  ) async {
    final store = testStore(points: 20, strikes: 2, penaltyPoints: 10);
    await store.load();
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    await openParentSetting(tester, const Key('penalty-settings'));
    expect(find.text('Штраф за страйки'), findsWidgets);
    expect(find.text('Страйки: 2 з 3'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('penalty-amount')), '15');
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-penalty')));
    await tester.pumpAndSettle();
    expect(store.penaltyPoints, 15);
    expect(find.text('Штраф збережено'), findsAtLeastNWidgets(1));

    await openParentSetting(tester, const Key('penalty-settings'));
    await tester.tap(find.byKey(const Key('clear-strikes')));
    await tester.pumpAndSettle();
    expect(store.strikes, 0);
    expect(find.text('Страйки скинуто'), findsAtLeastNWidgets(1));
  });

  testWidgets('parent settings can change game rounds and rest time', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    await openParentSetting(tester, const Key('game-limit-settings'));
    expect(find.text('Ліміт ігор'), findsWidgets);

    await tester.enterText(find.byKey(const Key('game-limit-rounds')), '3');
    await tester.enterText(find.byKey(const Key('game-limit-rest')), '30');
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-game-limit')));
    await tester.pumpAndSettle();
    expect(store.rewardedPlays, 3);
    expect(store.playLimitMinutes, 30);
    expect(find.text('Ліміт ігор збережено'), findsAtLeastNWidgets(1));
  });

  testWidgets('parent settings can change completion bonus', (tester) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.cute,
          home: const ParentSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    await openParentSetting(tester, const Key('completion-bonus-settings'));
    expect(find.text('Бонус за всі завдання'), findsWidgets);
    expect(store.completionBonusEnabled, isTrue);
    expect(store.completionBonusPoints, 10);

    TextField amountField() {
      return tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('completion-bonus-amount')),
          matching: find.byType(TextField),
        ),
      );
    }

    expect(amountField().enabled, isTrue);
    await tester.enterText(
      find.byKey(const Key('completion-bonus-amount')),
      '20',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('completion-bonus-enabled')));
    await tester.pump();
    expect(amountField().enabled, isFalse);
    await tester.tap(find.byKey(const Key('save-completion-bonus')));
    await tester.pumpAndSettle();
    expect(store.completionBonusEnabled, isFalse);
    expect(store.completionBonusPoints, 20);
    expect(find.text('Бонус збережено'), findsAtLeastNWidgets(1));
  });

  testWidgets('parent sheets close silently when nothing changed', (
    tester,
  ) async {
    final store = testStore(points: 20, strikes: 1);
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpParentSettings(tester, store);

    const sheets = [
      Key('settings-daily-tasks'),
      Key('settings-daily-optional-tasks'),
      Key('settings-goals'),
      Key('settings-bonus-points'),
      Key('completion-bonus-settings'),
      Key('game-limit-settings'),
      Key('penalty-settings'),
      Key('settings-password'),
      Key('settings-backup'),
    ];
    for (final key in sheets) {
      await openParentSetting(tester, key);
      await tester.tap(find.byKey(const Key('settings-sheet-close')));
      await tester.pumpAndSettle();
      expect(find.text(S.unsavedSettingsTitle), findsNothing);
      expect(find.byKey(const Key('settings-sheet-close')), findsNothing);
    }
  });

  testWidgets('parent sheets ask before discarding unsaved changes', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpParentSettings(tester, store);

    Future<void> expectDiscardPrompt() async {
      await tester.tap(find.byKey(const Key('settings-sheet-close')));
      await tester.pumpAndSettle();
      expect(find.text(S.unsavedSettingsTitle), findsOneWidget);
      await tester.tap(find.text(S.cancel));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-sheet-close')), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings-sheet-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.close));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-sheet-close')), findsNothing);
    }

    await openParentSetting(tester, const Key('game-limit-settings'));
    await tester.enterText(find.byKey(const Key('game-limit-rounds')), '3');
    await tester.pump();
    await expectDiscardPrompt();
    expect(store.rewardedPlays, AppConfig.rewardedPlays);

    await openParentSetting(tester, const Key('completion-bonus-settings'));
    await tester.tap(find.byKey(const Key('completion-bonus-enabled')));
    await tester.pump();
    await expectDiscardPrompt();
    expect(store.completionBonusEnabled, isTrue);

    await openParentSetting(tester, const Key('penalty-settings'));
    await tester.enterText(find.byKey(const Key('penalty-amount')), '15');
    await tester.pump();
    await expectDiscardPrompt();
    expect(store.penaltyPoints, AppConfig.defaultPenaltyPoints);

    await openParentSetting(tester, const Key('settings-password'));
    await tester.enterText(find.byType(TextField).first, '4826');
    await tester.pump();
    await expectDiscardPrompt();

    await openParentSetting(tester, const Key('settings-bonus-points'));
    await tester.enterText(find.byKey(const Key('bonus-amount')), '10');
    await tester.pump();
    await expectDiscardPrompt();
    expect(store.totalPoints, 0);
  });

  testWidgets('parent sheets save and close without a discard prompt', (
    tester,
  ) async {
    final store = testStore();
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpParentSettings(tester, store);

    await openParentSetting(tester, const Key('game-limit-settings'));
    await tester.enterText(find.byKey(const Key('game-limit-rounds')), '3');
    await tester.enterText(find.byKey(const Key('game-limit-rest')), '20');
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-game-limit')));
    await tester.pumpAndSettle();
    expect(find.text(S.unsavedSettingsTitle), findsNothing);
    expect(find.byKey(const Key('game-limit-rounds')), findsNothing);
    expect(store.rewardedPlays, 3);
    expect(store.playLimitMinutes, 20);
  });

  testWidgets('home splits mandatory and optional tasks', (tester) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
        HabitTask(
          id: 'help',
          title: 'Допомогти вдома',
          points: 8,
          icon: 'star',
          optional: true,
        ),
      ],
    );
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    expect(find.text('Завдання на сьогодні'), findsOneWidget);
    expect(find.text('Застелити ліжко'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Додаткові завдання'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Додаткові завдання'), findsOneWidget);
    expect(find.text('Допомогти вдома'), findsOneWidget);
    expect(find.text(S.optionalTasksHint), findsNothing);
    expect(find.byKey(const Key('add-today-task')), findsOneWidget);
  });

  testWidgets('home explains extra tasks when the list is empty', (
    tester,
  ) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text(S.optionalTasksHint),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Додаткові завдання'), findsOneWidget);
    expect(find.text(S.optionalTasksHint), findsOneWidget);
  });

  testWidgets('home can add a today-only task after parent approval', (
    tester,
  ) async {
    final store = testStore(
      tasks: const [
        HabitTask(id: 'bed', title: 'Застелити ліжко', points: 10, icon: 'bed'),
      ],
    );
    await store.load();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-today-task')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('add-today-task')));
    await tester.pump();

    expect(
      find.text('Введи пароль, щоб додати завдання на сьогодні'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    expect(find.text('Неправильний пароль'), findsOneWidget);
    expect(find.text('Додати завдання'), findsNothing);

    await tester.enterText(find.byType(TextField), '4826');
    await tester.tap(find.text('Перевірити'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Додати завдання'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Прогулянка');
    await tester.tap(find.text('Зберегти'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Прогулянка'), findsOneWidget);
    expect(find.text('Додаткові завдання'), findsOneWidget);
    expect(store.tasks, hasLength(2));
    expect(store.tasks.last.title, 'Прогулянка');
    expect(store.tasks.last.todayOnly, isTrue);
    expect(store.tasks.last.optional, isTrue);
    expect(store.dailyTasks, hasLength(1));
    expect(store.extraTasks, hasLength(1));
  });

  testWidgets('answer flash appears then fades away', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.cute,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showAnswerFlash(context),
                  child: const Text('go'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Молодець!'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Молодець!')).style?.decoration,
      TextDecoration.none,
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Молодець!'), findsNothing);
  });

  testWidgets('answer flash sits above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.cute,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showAnswerFlash(context),
                  child: const Text('go'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final center = tester.getCenter(find.text('Молодець!'));
    expect(center.dy, lessThan(320));

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });

  testWidgets('mascot keeps the same size for every mood', (tester) async {
    Future<Size> sizeFor(AxolotlMood mood) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AxolotlMascot(mood: mood, size: 128, animate: false),
          ),
        ),
      );
      await tester.pump();
      return tester.getSize(find.byType(AxolotlMascot));
    }

    const slot = Size(128, 128);
    expect(await sizeFor(AxolotlMood.happy), slot);
    expect(await sizeFor(AxolotlMood.cheer), slot);
    expect(await sizeFor(AxolotlMood.celebrate), slot);
  });

  testWidgets('game field keeps focus after the keyboard opens', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.cute,
        home: GameScaffold(
          title: 'Гра',
          mood: AxolotlMood.happy,
          child: GameInputBody(
            chrome: const [Text('Раунди')],
            prompt: const [Text('Підказка')],
            field: TextField(focusNode: focus),
            action: FilledButton(
              onPressed: () {},
              child: const Text('Перевірити'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(find.text('Раунди'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(focus.hasFocus, isTrue);
    expect(find.text('Раунди'), findsOneWidget);
  });
}
