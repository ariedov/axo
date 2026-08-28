import 'dart:convert';
import 'dart:io';

import 'package:app/config.dart';
import 'package:app/data/answer.dart';
import 'package:app/data/day_history_repository.dart';
import 'package:app/data/game_plays.dart';
import 'package:app/data/game_round.dart';
import 'package:app/data/goal_repository.dart';
import 'package:app/data/models.dart';
import 'package:app/data/onboarding_flags.dart';
import 'package:app/data/parent_auth.dart';
import 'package:app/data/points_repository.dart';
import 'package:app/data/task_repository.dart';
import 'package:app/data/today.dart';
import 'package:app/main.dart';
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
}) {
  return HabitStore(
    pointsRepo: InMemoryPointsRepository(points),
    taskRepo: InMemoryTaskRepository(
      TaskSnapshot(day: todayStamp(), tasks: tasks),
    ),
    parentAuth: InMemoryParentAuth(password),
    gamePlays: InMemoryGamePlaysRepository(),
    goalRepo: InMemoryGoalRepository([...goals]),
    historyRepo: InMemoryDayHistoryRepository(),
    celebrateFor: Duration.zero,
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
      goal: const RewardGoal(id: 'ice', title: 'Морозиво', cost: 50, icon: 'gift'),
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

    await store.verify('bed');
    expect(store.tasks.first.isVerified, isTrue);
    expect(store.totalPoints, 10);
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

  test('goals can be saved, reordered, and spent', () async {
    final store = testStore(
      points: 80,
      goals: const [
        RewardGoal(id: 'ice', title: 'Морозиво', cost: 50, icon: 'gift'),
        RewardGoal(id: 'park', title: 'Парк', cost: 100, icon: 'walk'),
      ],
    );
    await store.load();
    expect(store.goals.singleWhere((goal) => goal.id == 'ice').canAfford(80), isTrue);
    expect(store.goals.singleWhere((goal) => goal.id == 'park').canAfford(80), isFalse);

    await store.reorderGoals(0, 1);
    expect(store.goals.map((goal) => goal.id), ['park', 'ice']);

    expect(await store.spendGoal('ice'), isTrue);
    expect(store.totalPoints, 30);
    expect(store.goals.map((goal) => goal.id), ['park']);

    expect(await store.spendGoal('park'), isFalse);
    expect(store.totalPoints, 30);
    expect(store.goals, hasLength(1));
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
          home: Scaffold(
            body: GamePlaysBanner(gameId: 'english'),
          ),
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
    expect(find.text('Сьогодні балів більше немає — граємо для тренування'), findsOneWidget);
    expect(store.playsUsed('english'), 3);
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
    expect(find.text('Цілі'), findsOneWidget);
    expect(find.text('Поки немає цілей — додайте щось смачненьке.'), findsOneWidget);
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
    expect(find.text('Прогулянка'), findsNothing);
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

    expect(store.totalPoints, 30);
    expect(store.goals, isEmpty);
    expect(find.text('Ціль отримано!'), findsOneWidget);
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

    await tester.pumpWidget(AxolotlApp(store: store));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Календар'),
      300,
      scrollable: find.byType(Scrollable),
    );

    final now = DateTime.now();
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
    expect(store.goals, isEmpty);
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

    final bubbleSize = tester.getSize(find.byType(SpeechBubble));

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

    await tester.scrollUntilVisible(
      find.text('Множення'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Множення'), findsOneWidget);
    expect(find.text('Правопис'), findsOneWidget);
    expect(find.text('Англійська'), findsOneWidget);
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
    expect(store.tasks, hasLength(2));
    expect(store.tasks.last.title, 'Прогулянка');
    expect(store.tasks.last.todayOnly, isTrue);
    expect(store.dailyTasks, hasLength(1));
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

  testWidgets('game field keeps focus after the keyboard opens', (tester) async {
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
