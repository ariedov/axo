import 'package:flutter/material.dart';

import '../data/timer_repository.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'settings_sheet.dart';

Future<void> showTimerHistorySheet(BuildContext context) {
  return showParentSheet(
    context: context,
    builder: (context) => const TimerHistorySheet(),
  );
}

class TimerHistorySheet extends StatelessWidget {
  const TimerHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final history = store.timerHistory;

    return SettingsSheetScaffold(
      title: S.timer,
      hint: S.timerHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.blush, width: 2),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    S.timerEnabled,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Switch(
                  key: const Key('timer-enabled'),
                  value: store.timerEnabled,
                  onChanged: (value) => store.setTimerEnabled(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                S.timerNoHistory,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: history.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _TimerHistoryRow(session: history[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TimerHistoryRow extends StatelessWidget {
  const _TimerHistoryRow({required this.session});

  final TimerSession session;

  @override
  Widget build(BuildContext context) {
    final completed = session.status == TimerStatus.completed;
    final elapsed = Duration(milliseconds: session.elapsedMillis);
    final title = session.reason.isEmpty ? S.noReason : session.reason;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: completed ? AppColors.done : AppColors.waiting,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed ? AppColors.teal : AppColors.gold,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            color: completed ? AppColors.tealDark : AppColors.goldDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  S.timerOf(S.countdown(elapsed), S.countdown(session.target)),
                  style: TextStyle(
                    color: completed ? AppColors.tealDark : AppColors.goldDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  S.timerWhen(session.endedAt ?? session.startedAt),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            completed ? S.timerCompleted : S.timerAbandoned,
            style: TextStyle(
              color: completed ? AppColors.tealDark : AppColors.goldDeep,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
