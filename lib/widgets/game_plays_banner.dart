import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';

class GameLimitClock extends StatefulWidget {
  const GameLimitClock({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<GameLimitClock> createState() => _GameLimitClockState();
}

class _GameLimitClockState extends State<GameLimitClock> {
  Timer? _timer;

  void _syncTimer(bool locked) {
    if (locked && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (!HabitScope.of(context).gamesLocked) {
          _timer?.cancel();
          _timer = null;
        }
      });
    } else if (!locked && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer(HabitScope.of(context).gamesLocked);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncTimer(HabitScope.of(context).gamesLocked);
    return widget.builder(context);
  }
}

class GamePlaysBanner extends StatelessWidget {
  const GamePlaysBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GameLimitClock(
      builder: (context) {
        final store = HabitScope.of(context);
        if (store.gamesLocked) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Text(
                  S.gamePointsGone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.3,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.countdown(store.playsCooldown),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                    height: 1.1,
                    color: AppColors.goldDeep,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              Text(
                S.gamePointsLeft,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.goldDeep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                S.gameRoundsProgress(store.playsUsed, AppConfig.rewardedPlays),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 40,
                  height: 1.1,
                  color: AppColors.goldDeep,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
