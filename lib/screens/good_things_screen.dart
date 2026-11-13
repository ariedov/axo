import 'package:flutter/material.dart';

import '../data/today.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/day_highlight_dialog.dart';

/// Every "something good" note, newest first.
class GoodThingsScreen extends StatelessWidget {
  const GoodThingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final notes = store.goodThings;
    final hasToday = store.highlightOn(todayStamp(store.now())) != null;

    return Scaffold(
      appBar: AppBar(title: Text(S.goodThings)),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: hasToday
                        ? OutlinedButton.icon(
                            key: const Key('good-things-edit'),
                            onPressed: () => recordGoodThing(context),
                            icon: const Icon(Icons.edit_rounded),
                            label: Text(S.goodThingEdit),
                          )
                        : FilledButton.icon(
                            key: const Key('good-things-add'),
                            onPressed: () => recordGoodThing(context),
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: Text(S.goodThingsAddToday),
                          ),
                  ),
                  if (notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        children: [
                          const AxolotlMascot(
                            mood: AxolotlMood.happy,
                            size: 120,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            S.goodThingsEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final entry in notes)
                      _GoodThingTile(day: entry.day, note: entry.note),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoodThingTile extends StatelessWidget {
  const _GoodThingTile({required this.day, required this.note});

  final String day;
  final String note;

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final isToday = day == todayStamp(store.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        key: Key('good-thing-$day'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.blush, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.goldDeep,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    S.longDate(dateFromStamp(day)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.waiting,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      S.goodThingToday,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: AppColors.goldDeep,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
