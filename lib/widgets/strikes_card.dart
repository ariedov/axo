import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'parent_gate.dart';

class StrikesCard extends StatelessWidget {
  const StrikesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final strikes = store.strikes;
    final max = AppConfig.strikesToPenalty;
    final fill = (strikes / max).clamp(0.0, 1.0);
    final hot = strikes >= max - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: hot ? const Color(0xFFFFE4EC) : const Color(0xFFFFF4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (hot ? AppColors.pinkDark : AppColors.pink).withValues(
              alpha: hot ? 0.7 : 0.4,
            ),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 22,
                  color: hot ? AppColors.pinkDark : AppColors.pink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.strikes,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: hot ? AppColors.pinkDark : AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  S.strikesProgress(strikes, max),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: hot ? AppColors.pinkDark : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('add-strike'),
                  onPressed: store.canStrike ? () => _addStrike(context) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pinkDark,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(S.strike),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0xFFFFD6E0)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: ColoredBox(
                        color: hot ? AppColors.pinkDark : AppColors.pink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStrike(BuildContext context) async {
    if (!await askParent(context, message: S.strikePrompt)) return;
    if (!context.mounted) return;
    final store = HabitScope.of(context);
    if (store.strikes >= AppConfig.strikesToPenalty - 1) {
      if (!await showStrikePenaltyDialog(context, store.penaltyPoints)) {
        return;
      }
      if (!context.mounted) return;
    }
    HapticFeedback.mediumImpact();
    final result = await store.addStrike();
    if (!context.mounted) return;
    final text = result.penaltyHit
        ? S.penaltyHit(result.applied)
        : S.strikeGiven(store.strikes, AppConfig.strikesToPenalty);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

Future<bool> showStrikePenaltyDialog(BuildContext context, int points) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(S.strikePenaltyTitle),
      content: Text(S.strikePenaltyConfirm(points)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(S.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.pinkDark),
          child: const Text(S.continueAction),
        ),
      ],
    ),
  );
  return confirmed == true;
}
