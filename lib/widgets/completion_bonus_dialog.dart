import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'axolotl_mascot.dart';
import 'parent_gate.dart';

Future<void> verifyTaskWithBonus(
  BuildContext context,
  HabitTask task, {
  String? day,
}) async {
  final store = HabitScope.of(context);
  var awarded = false;
  await showParentTaskActions(
    context,
    onAward: () => awarded = true,
    onSendBack: () => store.reject(task.id, day: day),
  );
  if (!awarded || !context.mounted) return;
  HapticFeedback.mediumImpact();
  final bonus = await store.verify(task.id, day: day);
  if (!context.mounted || bonus <= 0) return;
  await showCompletionBonusDialog(context, points: bonus);
}

Future<void> showCompletionBonusDialog(
  BuildContext context, {
  required int points,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        key: const Key('completion-bonus-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AxolotlMascot(mood: AxolotlMood.happy, size: 140),
            const SizedBox(height: 8),
            const Text(
              S.completionBonusTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              S.plusPoints(points),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: AppColors.goldDeep,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.completionBonusEarned(points),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.3),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            key: const Key('completion-bonus-ok'),
            onPressed: () => Navigator.pop(context),
            child: const Text(S.ok),
          ),
        ],
      );
    },
  );
}
