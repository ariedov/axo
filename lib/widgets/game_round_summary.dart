import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'game_plays_banner.dart';

class GameRoundSummary extends StatelessWidget {
  const GameRoundSummary({
    super.key,
    required this.correct,
    required this.wrong,
    required this.points,
    required this.onContinue,
    this.title = S.roundDone,
    this.showCounts = true,
  });

  final int correct;
  final int wrong;
  final int points;
  final VoidCallback onContinue;
  final String title;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        const GamePlaysBanner(),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (showCounts || points > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.blush, width: 2),
            ),
            child: Column(
              children: [
                if (showCounts) ...[
                  _StatRow(
                    icon: Icons.check_rounded,
                    color: AppColors.tealDark,
                    label: S.correctCount,
                    value: correct,
                  ),
                  const SizedBox(height: 10),
                  _StatRow(
                    icon: Icons.close_rounded,
                    color: AppColors.pinkDark,
                    label: S.wrongCount,
                    value: wrong,
                  ),
                ],
                if (points > 0) ...[
                  if (showCounts) const SizedBox(height: 10),
                  Text(
                    '+${S.pointsWord(points)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppColors.goldDeep,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onContinue,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(S.next),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: color,
          ),
        ),
      ],
    );
  }
}
