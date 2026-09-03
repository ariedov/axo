import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'completed_goals_sheet.dart';
import 'goal_editor.dart';
import 'settings_sheet.dart';
import 'task_icons.dart';

Future<void> showGoalsSettingsSheet(BuildContext context) {
  return showParentSheet(
    context: context,
    builder: (context) => const ParentGoalsSheet(),
  );
}

Future<bool> showSpendGoalDialog(BuildContext context, RewardGoal goal) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(S.spendGoalTitle),
      content: Text(S.spendGoalConfirm(goal.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(S.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.goldDeep),
          child: const Text(S.spendGoal),
        ),
      ],
    ),
  );
  return confirmed == true;
}

class ParentGoalsSheet extends StatelessWidget {
  const ParentGoalsSheet({super.key});

  Future<void> _edit(BuildContext context, RewardGoal? existing) async {
    final result = await editGoalDialog(context, existing: existing);
    if (result == null || !context.mounted) return;
    final store = HabitScope.of(context);
    if (result.delete && existing != null) {
      await store.deleteGoal(existing.id);
      return;
    }
    if (result.goal != null) {
      await store.upsertGoal(result.goal!);
    }
  }

  Future<void> _spend(BuildContext context, RewardGoal goal) async {
    final confirmed = await showSpendGoalDialog(context, goal);
    if (!confirmed || !context.mounted) return;
    final spent = await HabitScope.of(context).spendGoal(
      goal.id,
      celebrate: false,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(spent ? S.spentGoal : S.notEnoughPoints)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final goals = store.activeGoals;

    return SettingsSheetScaffold(
      title: S.goals,
      hint: S.goalsHint,
      actions: [
        IconButton(
          key: const Key('completed-goals'),
          tooltip: S.completedGoals,
          onPressed: () => showCompletedGoalsSheet(context),
          icon: const Icon(Icons.history_rounded),
          color: AppColors.muted,
        ),
        IconButton(
          tooltip: S.addGoal,
          onPressed: () => _edit(context, null),
          icon: const Icon(Icons.add_circle_rounded),
          color: AppColors.pinkDark,
        ),
      ],
      child: goals.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                S.noGoalsYet,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: EdgeInsets.zero,
              itemCount: goals.length,
              onReorderItem: store.reorderGoals,
              proxyDecorator: reorderProxyDecorator,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Padding(
                  key: ValueKey(goal.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReorderableDelayedDragStartListener(
                    index: index,
                    child: _GoalRow(
                      goal: goal,
                      index: index,
                      points: store.totalPoints,
                      onTap: () => _edit(context, goal),
                      onSpend: () => _spend(context, goal),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.index,
    required this.points,
    required this.onTap,
    required this.onSpend,
  });

  final RewardGoal goal;
  final int index;
  final int points;
  final VoidCallback onTap;
  final VoidCallback onSpend;

  @override
  Widget build(BuildContext context) {
    final ready = goal.canAfford(points);

    return Material(
      color: ready ? const Color(0xFFFFF6D4) : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: ready ? AppColors.gold : AppColors.blush,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_handle_rounded, color: AppColors.muted),
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: TaskGlyph(
                  goal.icon,
                  size: 22,
                  color: ready ? AppColors.goldDeep : AppColors.pinkDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      S.goalProgress(points, goal.cost),
                      style: TextStyle(
                        color: ready ? AppColors.goldDeep : AppColors.pinkDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (ready)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilledButton(
                    onPressed: onSpend,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldDeep,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(S.spendGoal),
                  ),
                ),
              const Icon(Icons.edit_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
