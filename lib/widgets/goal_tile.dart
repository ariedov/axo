import 'package:flutter/material.dart';

import '../data/models.dart';
import '../strings.dart';
import '../theme.dart';
import 'task_icons.dart';

class GoalTile extends StatelessWidget {
  const GoalTile({
    super.key,
    required this.goal,
    required this.points,
    this.onSpend,
  });

  final RewardGoal goal;
  final int points;
  final VoidCallback? onSpend;

  @override
  Widget build(BuildContext context) {
    final ready = goal.canAfford(points);
    final remaining = goal.cost - points;
    final fill = goal.progress(points);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: ready ? const Color(0xFFFFF6D4) : AppColors.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: ready ? onSpend : null,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: ready ? AppColors.gold : AppColors.blush,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: TaskGlyph(
                    goal.icon,
                    size: 28,
                    color: ready ? AppColors.goldDeep : AppColors.pinkDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.goalProgress(points, goal.cost),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ready ? AppColors.goldDeep : AppColors.pinkDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ProgressBar(fill: fill, ready: ready),
                      const SizedBox(height: 6),
                      Text(
                        ready ? S.goalReady : S.pointsToGo(remaining),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: ready ? AppColors.tealDark : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ready)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.celebration_rounded,
                      color: AppColors.goldDeep,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fill, required this.ready});

  final double fill;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 12,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFFFE8D6)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fill,
              child: ColoredBox(
                color: ready ? AppColors.goldDeep : AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
