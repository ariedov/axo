import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'completion_bonus_dialog.dart';
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
    final tasks = store.tasksOn(day);
    final daily = [
      for (final task in tasks)
        if (task.isMandatory) task,
    ];
    final extra = [
      for (final task in tasks)
        if (task.optional || task.todayOnly) task,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  S.tasksForDay(day),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  S.pastDayHint,
                  style: TextStyle(
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
                        onSubmit: () => store.submit(task.id, day: day),
                        onUnsubmit: () => store.unsubmit(task.id, day: day),
                        onVerify: () => _verify(context, task),
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

  Future<void> _verify(BuildContext context, HabitTask task) {
    return verifyTaskWithBonus(context, task, day: day);
  }
}
