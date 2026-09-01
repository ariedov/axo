import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app/config.dart';
import 'package:app/data/answer.dart';
import 'package:app/data/backup.dart';
import 'package:app/data/day_history_repository.dart';
import 'package:app/data/division_problem.dart';
import 'package:app/data/game_catalog.dart';
import 'package:app/data/game_plays.dart';
import 'package:app/data/game_recents.dart';
import 'package:app/data/game_round.dart';
import 'package:app/data/memory_deck.dart';
import 'package:app/data/shuffled_deck.dart';
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
import 'package:app/state/habit_scope.dart';
import 'package:app/state/habit_store.dart';
import 'package:app/strings.dart';
import 'package:app/theme.dart';
import 'package:app/widgets/answer_flash.dart';
import 'package:app/widgets/axolotl_mascot.dart';
import 'package:app/widgets/game_input_body.dart';
import 'package:app/widgets/game_plays_banner.dart';
import 'package:app/widgets/game_scaffold.dart';
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
  GameRecentsRepository? gameRecents,
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
    historyRepo: InMemoryDayHistoryRepository(),
    strikesRepo: InMemoryStrikesRepository(
      StrikeSnapshot(
        count: strikes,
        day: strikeDay,
        penaltyPoints: penaltyPoints,
      ),
    ),
    celebrateFor: Duration.zero,
    now: now,
  );
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
    expect(store.totalPoints, 10);
    expect(store.todayEarnedPoints, 10);
    expect(store.todayPossiblePoints, 10);
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
    expect((json['data']['goals'] as List).single['completedOn'], isNotNull);
    expect(json['data']['history'], isA<Map<String, dynamic>>());
    expect(json['data']['gamePlays'], isA<Map<String, dynamic>>());
    expect(json['data']['strikes'], 0);
    expect(json['data']['penaltyPoints'], AppConfig.defaultPenaltyPoints);

    final encoded = snapshot.encode();
    expect(encoded.contains('secret-pass'), isFalse);
    expect(encoded.contains('parent_password'), isFalse);

    final restored = BackupSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(restored.points, 40);
    expect(restored.tasks.tasks.single.id, 'bed');
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
    },
  );

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

  test('games award points for the first three plays only', () async {
    final store = testStore();
    await store.load();

    expect(await store.tryAwardGamePlay('english'), 5);
    expect(await store.tryAwardGamePlay('english'), 5);
    expect(await store.tryAwardGamePlay('english'), 5);
    expect(await store.tryAwardGamePlay('english'), 0);
    expect(store.totalPoints, 15);
    expect(store.playsLeft('english'), 0);
    expect(await store.tryAwardGamePlay('spelling'), 5);
  });

  test('game rounds award different points by mode', () async {
    final store = testStore();
    await store.load();

    expect(await store.tryAwardGamePlay('times_tables', points: 1), 1);
    expect(store.totalPoints, 1);
    expect(await store.tryAwardGamePlay('times_tables', points: 3), 3);
    expect(await store.tryAwardGamePlay('times_tables', points: 5), 5);
    expect(await store.tryAwardGamePlay('times_tables', points: 5), 0);
    expect(store.totalPoints, 9);

    expect(await store.tryAwardGamePlay('english', points: 3), 3);
    expect(await store.tryAwardGamePlay('spelling', points: 5), 5);
  });

  testWidgets('game banner counts scored rounds as used out of three', (
    tester,
  ) async {
    final store = testStore();
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
    expect(find.text('Раунди з балами сьогодні'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);

    expect(await store.tryAwardGamePlay('english'), 5);
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);

    expect(await store.tryAwardGamePlay('english'), 5);
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);

    expect(await store.tryAwardGamePlay('english'), 5);
    await tester.pump();
    expect(
      find.text('Сьогодні балів більше немає — граємо для тренування'),
      findsOneWidget,
    );
    expect(store.playsUsed('english'), 3);
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
    expect(find.text('Застелити ліжко'), findsOneWidget);
    expect(find.text('Щоденні додаткові завдання'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Цілі'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Цілі'), findsOneWidget);
    expect(
      find.text('Поки немає цілей — додайте щось смачненьке.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Бонус і штраф'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Бонус і штраф'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Змінити пароль'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Змінити пароль'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Експортувати'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Резервна копія'), findsOneWidget);
    expect(find.byKey(const Key('export-backup')), findsOneWidget);
    expect(find.byKey(const Key('import-backup')), findsOneWidget);
    expect(
      find.text('Імпорт замінить усі дані на цьому телефоні.'),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text('Імпортувати'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
    tester.view.physicalSize = const Size(800, 2000);
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
    await tester.scrollUntilVisible(
      find.text('Імпортувати'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

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

    expect(find.text('Застелити ліжко'), findsOneWidget);
    expect(find.text('Щоденні додаткові завдання'), findsOneWidget);
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-daily-optional-task')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

    expect(find.text('Допомогти вдома'), findsOneWidget);
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

    await tester.scrollUntilVisible(
      find.text('Бонус і штраф'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

    await tester.scrollUntilVisible(
      find.text('Морозиво'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    await tester.tap(find.byKey(const Key('completed-goals')));
    await tester.pump();
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
    await tester.tap(find.text('Застелити ліжко'));
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
    expect(store.totalPoints, 52);
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

    await tester.scrollUntilVisible(
      find.text('Штраф за страйки'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Штраф за страйки'), findsOneWidget);
    expect(find.text('Страйки: 2 з 3'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('penalty-amount')), '15');
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-penalty')));
    await tester.pump();
    expect(store.penaltyPoints, 15);
    expect(find.text('Штраф збережено'), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(
      find.byKey(const Key('clear-strikes')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('clear-strikes')));
    await tester.pump();
    expect(store.strikes, 0);
    expect(find.text('Страйки скинуто'), findsAtLeastNWidgets(1));
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
