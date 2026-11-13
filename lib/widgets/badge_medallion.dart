import 'package:flutter/material.dart';

import '../data/badges.dart';
import '../theme.dart';

IconData badgeKindIcon(BadgeKind kind) => switch (kind) {
  BadgeKind.tasks => Icons.task_alt_rounded,
  BadgeKind.streak => Icons.local_fire_department_rounded,
  BadgeKind.goodThings => Icons.auto_awesome_rounded,
  BadgeKind.games => Icons.sports_esports_rounded,
  BadgeKind.perfectDays => Icons.workspace_premium_rounded,
  BadgeKind.points => Icons.stars_rounded,
  BadgeKind.goals => Icons.card_giftcard_rounded,
  BadgeKind.activeDays => Icons.event_available_rounded,
  BadgeKind.timerMinutes => Icons.hourglass_bottom_rounded,
  BadgeKind.goodStreak => Icons.favorite_rounded,
  BadgeKind.perfectWeekends => Icons.weekend_rounded,
  BadgeKind.daysWithAxo => Icons.pets_rounded,
};

Color badgeKindColor(BadgeKind kind) => switch (kind) {
  BadgeKind.tasks => AppColors.pinkDark,
  BadgeKind.streak => AppColors.goldDeep,
  BadgeKind.goodThings => AppColors.tealDark,
  BadgeKind.games => const Color(0xFF7C6BE0),
  BadgeKind.perfectDays => AppColors.pink,
  BadgeKind.points => AppColors.goldDeep,
  BadgeKind.goals => AppColors.pinkDark,
  BadgeKind.activeDays => AppColors.tealDark,
  BadgeKind.timerMinutes => const Color(0xFF7C6BE0),
  BadgeKind.goodStreak => AppColors.pink,
  BadgeKind.perfectWeekends => AppColors.goldDeep,
  BadgeKind.daysWithAxo => AppColors.teal,
};

/// A round medal with the badge icon and, optionally, its milestone number.
class BadgeMedallion extends StatelessWidget {
  const BadgeMedallion({
    super.key,
    required this.badge,
    required this.earned,
    this.size = 40,
    this.showTarget = true,
    this.onTap,
  });

  final HabitBadge badge;
  final bool earned;
  final double size;
  final bool showTarget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final medal = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gold, AppColors.goldDeep],
              )
            : null,
        color: earned ? null : const Color(0xFFEDE7EA),
        border: Border.all(
          color: earned ? Colors.white : const Color(0xFFDBD3D8),
          width: 2,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: AppColors.goldDeep.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        badgeKindIcon(badge.kind),
        size: size * 0.45,
        color: earned ? Colors.white : const Color(0xFFB3A8AE),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(onTap: onTap, child: medal),
        if (showTarget)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${badge.target}',
              style: TextStyle(
                fontSize: size * 0.24,
                fontWeight: FontWeight.w900,
                color: earned ? AppColors.goldDeep : AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}
