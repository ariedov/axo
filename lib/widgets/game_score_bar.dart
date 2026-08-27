import 'package:flutter/material.dart';

import '../config.dart';
import '../data/game_round.dart';
import '../strings.dart';
import '../theme.dart';

class GameScoreBar extends StatelessWidget {
  const GameScoreBar({super.key, required this.round, required this.infinite});

  final GameRound round;
  final bool infinite;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, color: AppColors.tealDark),
            const SizedBox(width: 4),
            Text(
              '${round.correct}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.tealDark,
              ),
            ),
            const SizedBox(width: 20),
            const Icon(Icons.close_rounded, color: AppColors.pinkDark),
            const SizedBox(width: 4),
            Text(
              '${round.wrong}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.pinkDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          infinite
              ? S.practiceMode
              : '${round.answered}/${AppConfig.roundLength}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
