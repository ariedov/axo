import 'package:flutter/material.dart';

import '../data/badges.dart';
import '../state/habit_scope.dart';
import '../state/habit_store.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/badge_award_dialog.dart';
import '../widgets/badge_medallion.dart';

/// Every badge, grouped by what earns it.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final stats = store.badgeStats;
    final kinds = badgeKindsByAchievement(stats);

    return Scaffold(
      appBar: AppBar(title: Text(S.badges)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.peach, Color(0xFFFFE4EC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 28),
                children: [
                  for (final kind in kinds)
                    _KindSection(
                      kind: kind,
                      value: stats.of(kind),
                      store: store,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KindSection extends StatelessWidget {
  const _KindSection({
    required this.kind,
    required this.value,
    required this.store,
  });

  final BadgeKind kind;
  final int value;
  final HabitStore store;

  @override
  Widget build(BuildContext context) {
    final next = nextBadgeFor(kind, value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        key: Key('badge-kind-${kind.name}'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.blush, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  badgeKindIcon(kind),
                  size: 18,
                  color: badgeKindColor(kind),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    S.badgeKindLabel(kind),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  next == null
                      ? S.badgeAllEarned
                      : S.badgeProgress(value, next.target),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                for (final badge in badgesOf(kind))
                  BadgeMedallion(
                    key: Key('badge-all-${badge.id}'),
                    badge: badge,
                    earned: value >= badge.target,
                    size: 44,
                    onTap: () => showBadgeInfoDialog(
                      context,
                      badge,
                      earned: value >= badge.target,
                      value: value,
                      earnedOn: store.badgeEarnedOn(badge.id),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
