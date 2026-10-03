import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../data/audio_service.dart';
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
  // Verifying the last waiting task removes the approve button (and possibly
  // this tile) while the award is still being persisted. Capture the
  // navigator up front so the bonus dialog can still be shown afterwards.
  final navigator = Navigator.of(context);
  final bonus = await store.verify(task.id, day: day);
  if (bonus <= 0 || !navigator.mounted) return;
  await showCompletionBonusDialog(
    navigator.context,
    points: bonus,
    streakPoints: store.lastStreakBonus,
  );
}

Future<void> verifySubmittedDailyWithBonus(
  BuildContext context, {
  String? day,
}) async {
  if (!await askParent(context, message: S.approveCompletedPrompt)) return;
  if (!context.mounted) return;
  HapticFeedback.mediumImpact();
  AudioService.instance.play(SoundEffect.taskComplete);
  final store = HabitScope.of(context);
  // Approving the last waiting task removes this button while the awards are
  // still being persisted, unmounting its context before the bonus is known.
  // Capture the navigator up front so the bonus dialog can still be shown.
  final navigator = Navigator.of(context);
  final bonus = await store.verifySubmittedDaily(day: day);
  if (bonus <= 0 || !navigator.mounted) return;
  await showCompletionBonusDialog(
    navigator.context,
    points: bonus,
    streakPoints: store.lastStreakBonus,
  );
}

Future<void> showCompletionBonusDialog(
  BuildContext context, {
  required int points,
  int streakPoints = 0,
}) {
  final streak = streakPoints < 0
      ? 0
      : (streakPoints > points ? points : streakPoints);
  final base = points - streak;
  AudioService.instance.play(SoundEffect.allDone);
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
            if (base > 0)
              Text(
                S.plusPoints(base),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: AppColors.goldDeep,
                ),
              ),
            if (streak > 0) ...[
              if (base > 0) const SizedBox(height: 4),
              Text(
                S.streakBonusAwarded(streak),
                key: const Key('completion-bonus-streak'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: base > 0 ? 20 : 28,
                  color: base > 0 ? AppColors.tealDark : AppColors.goldDeep,
                ),
              ),
            ],
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
