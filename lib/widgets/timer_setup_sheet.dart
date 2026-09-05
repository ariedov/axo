import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'timer_clock.dart';

class TimerSetupResult {
  const TimerSetupResult({required this.duration, required this.reason});

  final Duration duration;
  final String reason;
}

Future<TimerSetupResult?> showTimerSetupDialog(BuildContext context) {
  return showDialog<TimerSetupResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TimerSetupDialog(),
  );
}

class _TimerSetupDialog extends StatefulWidget {
  const _TimerSetupDialog();

  @override
  State<_TimerSetupDialog> createState() => _TimerSetupDialogState();
}

class _TimerSetupDialogState extends State<_TimerSetupDialog> {
  final _reason = TextEditingController();
  var _minutes = AppConfig.timerDefaultMinutes;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Duration get _duration => Duration(minutes: _minutes);

  void _setMinutes(int value) {
    final next = value.clamp(
      AppConfig.timerMinMinutes,
      AppConfig.timerMaxMinutes,
    );
    if (next == _minutes) return;
    setState(() => _minutes = next);
  }

  void _start() {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      TimerSetupResult(duration: _duration, reason: _reason.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(S.timer),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TimerClock(
              key: const Key('timer-setup-clock'),
              progress: _minutes / AppConfig.timerMaxMinutes,
              label: S.countdown(_duration),
              size: 200,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const Key('timer-minus'),
                  onPressed: () => _setMinutes(_minutes - 1),
                  icon: const Icon(Icons.remove_circle_rounded),
                  color: AppColors.pinkDark,
                  iconSize: 32,
                ),
                Text(
                  S.minutesWord(_minutes),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  key: const Key('timer-plus'),
                  onPressed: () => _setMinutes(_minutes + 1),
                  icon: const Icon(Icons.add_circle_rounded),
                  color: AppColors.pinkDark,
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final minutes in AppConfig.timerPresetsMinutes)
                  ChoiceChip(
                    key: Key('timer-preset-$minutes'),
                    label: Text('$minutes'),
                    selected: _minutes == minutes,
                    onSelected: (_) => _setMinutes(minutes),
                    selectedColor: AppColors.pink,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _minutes == minutes ? Colors.white : AppColors.ink,
                    ),
                    side: const BorderSide(color: AppColors.blush, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LabeledField(
              key: const Key('timer-reason'),
              controller: _reason,
              label: '${S.timerReason} · ${S.timerReasonHint}',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _start(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(S.cancel),
        ),
        FilledButton(
          key: const Key('timer-start'),
          onPressed: _start,
          child: const Text(S.timerStart),
        ),
      ],
    );
  }
}
