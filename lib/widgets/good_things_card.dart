import 'package:flutter/material.dart';

import '../data/today.dart';
import '../screens/good_things_screen.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'day_highlight_dialog.dart';

/// Entry point to the "good things" log, shown right under the mascot.
class GoodThingsCard extends StatelessWidget {
  const GoodThingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final count = store.goodThings.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
        child: TextButton(
          key: const Key('good-things-card'),
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const GoodThingsScreen()),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.pinkDark,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            count == 0
                ? S.goodThings
                : '${S.goodThings} · ${S.goodThingsCount(count)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.pinkDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets the child write down a good thing even before every task is done.
class GoodThingButton extends StatelessWidget {
  const GoodThingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final note = store.highlightOn(todayStamp(store.now()));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
      child: Material(
        color: note == null ? AppColors.waiting : AppColors.done,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const Key('good-thing-button'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => recordGoodThing(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Icon(
                  note == null
                      ? Icons.auto_awesome_rounded
                      : Icons.check_circle_rounded,
                  size: 22,
                  color: note == null ? AppColors.goldDeep : AppColors.tealDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note == null ? S.goodThingAdd : S.goodThingToday,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note ?? S.goodThingAddHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: note == null
                              ? FontWeight.w700
                              : FontWeight.w800,
                          fontSize: 12,
                          color: note == null ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.pinkDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
