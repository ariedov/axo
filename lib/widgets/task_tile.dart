import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../strings.dart';
import '../theme.dart';
import 'task_icons.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onSubmit,
    required this.onUnsubmit,
    required this.onVerify,
  });

  static const height = 120.0;
  static const actionWidth = 108.0;
  static const actionHeight = 44.0;
  static const titleHeight = 44.0;

  final HabitTask task;
  final VoidCallback onSubmit;
  final VoidCallback onUnsubmit;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final colors = switch (task.status) {
      TaskStatus.pending => (AppColors.card, AppColors.blush),
      TaskStatus.submitted => (AppColors.waiting, const Color(0xFFFFD27A)),
      TaskStatus.verified => (AppColors.done, AppColors.teal),
    };

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.2,
      decoration: task.isVerified ? TextDecoration.lineThrough : null,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: colors.$1,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.$2, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _StatusMark(status: task.status, icon: task.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: titleHeight,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.plusPoints(task.points),
                                maxLines: 1,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.pinkDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                switch (task.status) {
                                  TaskStatus.submitted => S.waiting,
                                  TaskStatus.verified => S.verified,
                                  TaskStatus.pending => '',
                                },
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: task.isVerified
                                          ? AppColors.tealDark
                                          : AppColors.goldDeep,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: actionWidth,
                          height: actionHeight,
                          child: _Action(
                            task: task,
                            onSubmit: onSubmit,
                            onUnsubmit: onUnsubmit,
                            onVerify: onVerify,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.status, required this.icon});

  final TaskStatus status;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white,
      child: switch (status) {
        TaskStatus.verified => const Icon(
          Icons.check_rounded,
          color: AppColors.tealDark,
          size: 28,
        ),
        TaskStatus.submitted => const Icon(
          Icons.hourglass_top_rounded,
          color: AppColors.goldDeep,
          size: 26,
        ),
        TaskStatus.pending => TaskGlyph(icon, size: 26),
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.task,
    required this.onSubmit,
    required this.onUnsubmit,
    required this.onVerify,
  });

  final HabitTask task;
  final VoidCallback onSubmit;
  final VoidCallback onUnsubmit;
  final VoidCallback onVerify;

  ButtonStyle get _buttonStyle => FilledButton.styleFrom(
    minimumSize: const Size(0, TaskTile.actionHeight),
    maximumSize: const Size(TaskTile.actionWidth, TaskTile.actionHeight),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );

  @override
  Widget build(BuildContext context) {
    if (task.isVerified) {
      return const Center(
        child: Icon(Icons.verified_rounded, color: AppColors.tealDark, size: 32),
      );
    }

    if (task.isSubmitted) {
      return Row(
        children: [
          SizedBox(
            width: 40,
            height: TaskTile.actionHeight,
            child: IconButton(
              onPressed: onUnsubmit,
              tooltip: S.notYet,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.undo_rounded),
              color: AppColors.muted,
            ),
          ),
          Expanded(
            child: FilledButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onVerify();
              },
              style: _buttonStyle.copyWith(
                backgroundColor: const WidgetStatePropertyAll(AppColors.goldDeep),
              ),
              child: const FittedBox(child: Text(S.verify)),
            ),
          ),
        ],
      );
    }

    return FilledButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onSubmit();
      },
      style: _buttonStyle,
      child: const FittedBox(child: Text(S.done)),
    );
  }
}
