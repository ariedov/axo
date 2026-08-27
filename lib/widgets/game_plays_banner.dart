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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        capped
            ? S.gamePointsGone
            : '${S.gamePointsLeft}: ${S.gameRoundsProgress(used, max)}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: capped ? AppColors.muted : AppColors.goldDeep,
        ),
      ),
    );
  }
}
