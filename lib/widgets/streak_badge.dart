import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.done,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.tealDark,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              S.streak(days),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppColors.tealDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
