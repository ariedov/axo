import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'data/audio_service.dart';
import 'data/completion_bonus.dart';
import 'data/day_history_repository.dart';
import 'data/game_limit.dart';
import 'data/goal_repository.dart';
import 'data/local_reminders.dart';
import 'data/onboarding_flags.dart';
import 'data/parent_auth.dart';
import 'data/points_repository.dart';
import 'data/game_plays.dart';
import 'data/game_recents.dart';
import 'data/reminder_settings.dart';
import 'data/strikes_repository.dart';
import 'data/task_repository.dart';
import 'data/timer_repository.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/habit_scope.dart';
import 'state/habit_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.instance.preload();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final store = HabitStore(
    pointsRepo: LocalPointsRepository(
      (key, fallback) async => prefs.getInt(key) ?? fallback,
      (key, value) async {
        await prefs.setInt(key, value);
      },
    ),
    taskRepo: LocalTaskRepository((key) async => prefs.getString(key), (
      key,
      value,
    ) async {
      await prefs.setString(key, value);
    }),
    parentAuth: LocalParentAuth((key) async => prefs.getString(key), (
      key,
      value,
    ) async {
      await prefs.setString(key, value);
    }),
    gamePlays: LocalGamePlaysRepository((key) async => prefs.getString(key), (
      key,
      value,
    ) async {
      await prefs.setString(key, value);
    }),
    gameRecents: LocalGameRecentsRepository(
      (key) async => prefs.getString(key),
      (key, value) async {
        await prefs.setString(key, value);
      },
    ),
    goalRepo: LocalGoalRepository((key) async => prefs.getString(key), (
      key,
      value,
    ) async {
      await prefs.setString(key, value);
    }),
    historyRepo: LocalDayHistoryRepository(
      (key) async => prefs.getString(key),
      (key, value) async {
        await prefs.setString(key, value);
      },
    ),
    onboardingFlags: LocalOnboardingFlags((key) async => prefs.getBool(key), (
      key,
      value,
    ) async {
      await prefs.setBool(key, value);
    }),
    strikesRepo: LocalStrikesRepository((key) async => prefs.getString(key), (
      key,
      value,
    ) async {
      await prefs.setString(key, value);
    }),
    gameLimitRepo: LocalGameLimitRepository(
      (key) async => prefs.getString(key),
      (key, value) async {
        await prefs.setString(key, value);
      },
    ),
    completionBonusRepo: LocalCompletionBonusRepository(
      (key) async => prefs.getString(key),
      (key, value) async {
        await prefs.setString(key, value);
      },
    ),
    timerRepo: LocalTimerRepository((key) async => prefs.getString(key), (
      key,
      value,
    ) async {
      await prefs.setString(key, value);
    }),
    reminderSettingsRepo: LocalReminderSettingsRepository(
      (key) async => prefs.getString(key),
      (key, value) async {
        await prefs.setString(key, value);
      },
    ),
    reminders: LocalReminderScheduler(),
  );
  await store.load();
  runApp(AxolotlApp(store: store));
}

class AxolotlApp extends StatefulWidget {
  const AxolotlApp({super.key, required this.store});

  final HabitStore store;

  @override
  State<AxolotlApp> createState() => _AxolotlAppState();
}

class _AxolotlAppState extends State<AxolotlApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.store.syncReminders());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        widget.store.ensureToday().whenComplete(widget.store.syncReminders),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HabitScope(
      store: widget.store,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            locale: const Locale('uk'),
            supportedLocales: const [Locale('uk'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.cute,
            home: widget.store.needsOnboarding
                ? const OnboardingScreen()
                : const HomeScreen(),
          );
        },
      ),
    );
  }
}
