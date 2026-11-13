import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/badges.dart';
import '../data/today.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'axolotl_mascot.dart';
import 'badge_medallion.dart';

/// Celebrates one or more freshly earned badges.
Future<void> showBadgeAwardDialog(
  BuildContext context,
  List<HabitBadge> badges,
) {
  if (badges.isEmpty) return Future.value();
  HapticFeedback.mediumImpact();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        key: const Key('badge-award-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AxolotlMascot(mood: AxolotlMood.happy, size: 112),
              const SizedBox(height: 4),
              Text(
                S.badgeEarnedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final badge in badges)
                    SizedBox(
                      width: 78,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BadgeMedallion(
                            key: Key('awarded-${badge.id}'),
                            badge: badge,
                            earned: true,
                            size: 52,
                            showTarget: false,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            S.badgeTierName(badge.tier),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            S.badgeRequirement(badge.kind, badge.target),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                S.badgeEarnedBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            key: const Key('badge-award-ok'),
            onPressed: () => Navigator.pop(context),
            child: Text(S.ok),
          ),
        ],
      );
    },
  );
}

/// Explains a single badge: what it took and whether it is already earned.
Future<void> showBadgeInfoDialog(
  BuildContext context,
  HabitBadge badge, {
  required bool earned,
  required int value,
  String? earnedOn,
}) {
  final store = HabitScope.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        key: Key('badge-dialog-${badge.id}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeMedallion(
              badge: badge,
              earned: earned,
              size: 88,
              showTarget: false,
            ),
            const SizedBox(height: 10),
            Text(
              S.badgeTierName(badge.tier),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              S.badgeRequirement(badge.kind, badge.target),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              earned && earnedOn != null
                  ? S.badgeEarnedOn(S.shortDate(dateFromStamp(earnedOn)))
                  : earned
                  ? S.badgeEarnedOn(S.shortDate(store.now()))
                  : S.badgeProgress(value, badge.target),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: earned ? AppColors.goldDeep : AppColors.muted,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.close),
          ),
        ],
      );
    },
  );
}
