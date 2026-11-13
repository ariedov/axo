import 'package:flutter/material.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'settings_sheet.dart';

Future<void> showReminderSettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => ReminderSettingsSection(messenger: messenger),
  );
}

class ReminderSettingsSection extends StatefulWidget {
  const ReminderSettingsSection({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  State<ReminderSettingsSection> createState() =>
      _ReminderSettingsSectionState();
}

class _ReminderSettingsSectionState extends State<ReminderSettingsSection> {
  var _enabled = true;
  var _hour = 21;
  var _minute = 0;
  var _moodNudges = true;
  var _missesYou = true;
  var _seeded = false;
  var _initialEnabled = true;
  var _initialHour = 21;
  var _initialMinute = 0;
  var _initialMoodNudges = true;
  var _initialMissesYou = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final store = HabitScope.of(context);
    _enabled = store.eveningReminderEnabled;
    _hour = store.eveningReminderHour;
    _minute = store.eveningReminderMinute;
    _moodNudges = store.moodNudgesEnabled;
    _missesYou = store.missesYouEnabled;
    _initialEnabled = _enabled;
    _initialHour = _hour;
    _initialMinute = _minute;
    _initialMoodNudges = _moodNudges;
    _initialMissesYou = _missesYou;
    _seeded = true;
  }

  bool get _dirty =>
      _enabled != _initialEnabled ||
      _hour != _initialHour ||
      _minute != _initialMinute ||
      _moodNudges != _initialMoodNudges ||
      _missesYou != _initialMissesYou;

  void _toast(String text) => showParentToast(widget.messenger, text);

  Future<void> _pickTime() async {
    if (!_enabled) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
  }

  Future<void> _save() async {
    final store = HabitScope.of(context);
    await store.setEveningReminder(
      enabled: _enabled,
      hour: _hour,
      minute: _minute,
    );
    await store.setMoodNudges(enabled: _moodNudges, missesYou: _missesYou);
    if (!mounted) return;
    if ((_enabled || _moodNudges) && !await store.reminders.hasPermission()) {
      _toast(S.notificationsDenied);
    } else {
      _toast(S.remindersSaved);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canSchedule = HabitScope.of(context).reminders.canSchedule;
    return SettingsSheetScaffold(
      title: S.reminders,
      hint: canSchedule ? S.remindersHint : S.remindersWebHint,
      dirty: _dirty,
      child: SingleChildScrollView(
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
                  Expanded(
                    child: Text(
                      S.eveningReminder,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    key: const Key('evening-reminder-enabled'),
                    value: _enabled,
                    onChanged: canSchedule
                        ? (value) => setState(() => _enabled = value)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: _enabled ? Colors.white : AppColors.peach,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: const Key('evening-reminder-time'),
                onTap: _enabled && canSchedule ? _pickTime : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.blush, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.eveningReminderTime,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.clockTime(_hour, _minute),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.blush, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      S.moodNudges,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    key: const Key('mood-nudges-enabled'),
                    value: _moodNudges,
                    onChanged: canSchedule
                        ? (value) => setState(() => _moodNudges = value)
                        : null,
                  ),
                ],
              ),
            ),
            if (_moodNudges) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.blush, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.missesYouNudges,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Switch(
                      key: const Key('misses-you-enabled'),
                      value: _missesYou,
                      onChanged: canSchedule
                          ? (value) => setState(() => _missesYou = value)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              S.moodNudgesHint,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-reminders'),
              onPressed: _save,
              child: Text(S.save),
            ),
          ],
        ),
      ),
    );
  }
}
