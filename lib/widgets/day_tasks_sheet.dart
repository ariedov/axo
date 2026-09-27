import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/habit_scope.dart';
import '../state/habit_store.dart';
import '../strings.dart';
import '../theme.dart';
import 'completion_bonus_dialog.dart';
import 'parent_gate.dart';
import 'task_tile.dart';

Future<void> showDayTasksSheet(BuildContext context, String day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => DayTasksSheet(key: Key('day-tasks-$day'), day: day),
  );
}

class DayTasksSheet extends StatelessWidget {
  const DayTasksSheet({super.key, required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final locked = store.isDayLocked(day);
    final tasks = store.tasksOn(day);
    final daily = [
      for (final task in tasks)
        if (task.isMandatory) task,
    ];
    final extra = [
      for (final task in tasks)
        if (task.optional) task,
    ];
    final progress = DayProgress.fromTasks(day, tasks);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 4, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        S.tasksForDay(day),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('day-lock'),
                      tooltip: locked ? S.dayUnlock : S.dayLock,
                      onPressed: () => _toggleLock(context, store, locked),
                      icon: Icon(
                        locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      ),
                      color: locked ? AppColors.pinkDark : AppColors.muted,
                    ),
                  ],
                ),
              ),
              if (progress.total > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    S.dayTasksProgress(progress.completed, progress.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.pinkDark,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  locked ? S.dayLockedHint : S.pastDayHint,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final task in daily)
                      TaskTile(
                        task: task,
                        enabled: !locked,
                        onSubmit: () => store.submit(task.id, day: day),
                        onUnsubmit: () => store.unsubmit(task.id, day: day),
                        onVerify: () => _verify(context, task),
                      ),
                    if (!locked && daily.any((task) => task.isSubmitted))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            key: const Key('approve-completed'),
                            onPressed: () => verifySubmittedDailyWithBonus(
                              context,
                              day: day,
                            ),
                            child: const Text(
                              S.approveCompleted,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (extra.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Text(
                          S.optionalTasks,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      for (final task in extra)
                        TaskTile(
                          task: task,
                          enabled: !locked,
                          onSubmit: () => store.submit(task.id, day: day),
                          onUnsubmit: () => store.unsubmit(task.id, day: day),
                          onVerify: () => _verify(context, task),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLock(
    BuildContext context,
    HabitStore store,
    bool locked,
  ) async {
    if (locked) {
      final allowed = await askParent(context, message: S.dayUnlockPrompt);
      if (!allowed || !context.mounted) return;
      await store.setDayLocked(day, false);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const Key('day-lock-dialog'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(S.dayLockTitle),
          content: const Text(S.dayLockBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(S.cancel),
            ),
            FilledButton(
              key: const Key('day-lock-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(S.dayLockConfirm),
            ),
          ],
        );
      },
    );
    if (confirm != true || !context.mounted) return;
    final allowed = await askParent(context, message: S.dayLockPrompt);
    if (!allowed || !context.mounted) return;
    await store.setDayLocked(day, true);
  }

  Future<void> _verify(BuildContext context, HabitTask task) {
    return verifyTaskWithBonus(context, task, day: day);
  }
}
