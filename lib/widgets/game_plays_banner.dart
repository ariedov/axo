import 'package:flutter/material.dart';

import '../config.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';

class GamePlaysBanner extends StatelessWidget {
  const GamePlaysBanner({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final used = store.playsUsed(gameId);
    final max = AppConfig.rewardedPlaysPerGame;
    final capped = used >= max;

    if (capped) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          S.gamePointsGone,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.3,
            color: AppColors.muted,
          ),
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
            S.gameRoundsProgress(used, max),
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
}
