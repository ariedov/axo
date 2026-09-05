import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../strings.dart';
import '../theme.dart';
import 'timer_clock.dart';

class TimerSetupResult {
  const TimerSetupResult({required this.duration, required this.reason});

  final Duration duration;
  final String reason;
}

Future<TimerSetupResult?> showTimerSetupDialog(BuildContext context) {
  return showModalBottomSheet<TimerSetupResult>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _TimerSetupSheet(),
  );
}

class _TimerSetupSheet extends StatefulWidget {
  const _TimerSetupSheet();

  @override
  State<_TimerSetupSheet> createState() => _TimerSetupSheetState();
}

class _TimerSetupSheetState extends State<_TimerSetupSheet> {
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
    HapticFeedback.selectionClick();
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
              TimerClock(
                key: const Key('timer-setup-clock'),
                progress: _minutes / AppConfig.timerMaxMinutes,
                label: S.countdown(_duration),
                size: 148,
                onMinutes: _setMinutes,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final minutes in AppConfig.timerPresetsMinutes)
                    ChoiceChip(
                      key: Key('timer-preset-$minutes'),
                      label: Text('$minutes'),
                      visualDensity: VisualDensity.compact,
                      selected: _minutes == minutes,
                      onSelected: (_) => _setMinutes(minutes),
                      selectedColor: AppColors.pink,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _minutes == minutes
                            ? Colors.white
                            : AppColors.ink,
                      ),
                      side: const BorderSide(color: AppColors.blush, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('timer-reason'),
                controller: _reason,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _start(),
                style: const TextStyle(fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  hintText: '${S.timerReason} · ${S.timerReasonHint}',
                  prefixIcon: Icon(Icons.edit_rounded),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('timer-start'),
                  onPressed: _start,
                  child: const Text(S.timerStart),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
