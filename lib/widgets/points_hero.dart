import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

class PointsHero extends StatelessWidget {
  const PointsHero({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6D4), Color(0xFFFFE7A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, size: 32, color: AppColors.goldDeep),
          const SizedBox(height: 4),
          Text(
            '$points',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 64,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.goldDeep,
            ),
          ),
          Text(
            S.pointsWord(points).split(' ').last,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.goldDeep.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
