import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'settings_sheet.dart';
import 'task_editor.dart';
import 'task_icons.dart';

Future<void> showDailyTasksSheet(
  BuildContext context, {
  bool optional = false,
}) {
  return showParentSheet(
    context: context,
    builder: (context) => ParentTasksSheet(optional: optional),
  );
}

class ParentTasksSheet extends StatelessWidget {
  const ParentTasksSheet({super.key, this.optional = false});

  final bool optional;

  Future<void> _edit(BuildContext context, HabitTask? existing) async {
    final result = await editTaskDialog(
      context,
      existing: existing,
      optional: existing?.optional ?? optional,
    );
    if (result == null || !context.mounted) return;
    final store = HabitScope.of(context);
    if (result.delete && existing != null) {
      await store.deleteTask(existing.id);
      return;
    }
    if (result.task != null) {
      await store.upsertTask(result.task!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final tasks = optional ? store.dailyOptionalTasks : store.dailyTasks;

    return SettingsSheetScaffold(
      title: optional ? S.dailyOptionalTasks : S.dailyTasks,
      hint: optional ? S.dailyOptionalTasksHint : S.dailyTasksHint,
      actions: [
        IconButton(
          key: optional ? const Key('add-daily-optional-task') : null,
          tooltip: S.addTask,
          onPressed: () => _edit(context, null),
          icon: const Icon(Icons.add_circle_rounded),
          color: AppColors.pinkDark,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            S.reorderTasksHint,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.zero,
              itemCount: tasks.length,
              onReorderItem: optional
                  ? store.reorderDailyOptionalTasks
                  : store.reorderDailyTasks,
              proxyDecorator: reorderProxyDecorator,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  key: ValueKey(task.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReorderableDelayedDragStartListener(
                    index: index,
                    child: _DailyTaskRow(
                      task: task,
                      index: index,
                      onTap: () => _edit(context, task),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTaskRow extends StatelessWidget {
  const _DailyTaskRow({
    required this.task,
    required this.index,
    required this.onTap,
  });

  final HabitTask task;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.blush, width: 2),
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
                child: TaskGlyph(task.icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      S.plusPoints(task.points),
                      style: const TextStyle(
                        color: AppColors.pinkDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
