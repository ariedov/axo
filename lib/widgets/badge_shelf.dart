import 'package:flutter/material.dart';

import '../data/badges.dart';
import '../state/habit_scope.dart';
import '../state/habit_store.dart';
import '../strings.dart';
import 'badge_award_dialog.dart';
import 'badge_medallion.dart';

/// One compact, scrollable row: the current badge each category has reached,
/// ordered by how far the child has got.
class BadgeShelf extends StatelessWidget {
  const BadgeShelf({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final stats = store.badgeStats;
    final kinds = badgeKindsByAchievement(stats);

    return Semantics(
      label: S.badges,
      container: true,
      child: SingleChildScrollView(
        key: const Key('badge-row'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
        child: Row(
          children: [
            for (var index = 0; index < kinds.length; index++) ...[
              if (index > 0) const SizedBox(width: 16),
              _Entry(
                kind: kinds[index],
                value: stats.of(kinds[index]),
                store: store,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.kind, required this.value, required this.store});

  final BadgeKind kind;
  final int value;
  final HabitStore store;

  @override
  Widget build(BuildContext context) {
    final badge = currentBadgeFor(kind, value);
    final earned = earnedBadgeFor(kind, value) != null;
    return BadgeMedallion(
      key: Key('badge-${badge.id}'),
      badge: badge,
      earned: earned,
      size: 48,
      onTap: () => showBadgeInfoDialog(
        context,
        badge,
        earned: earned,
        value: value,
        earnedOn: store.badgeEarnedOn(badge.id),
      ),
    );
  }
}
