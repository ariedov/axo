import 'package:flutter/material.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'settings_sheet.dart';

Future<void> showDayHighlightSettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => DayHighlightSettingsSection(messenger: messenger),
  );
}

class DayHighlightSettingsSection extends StatefulWidget {
  const DayHighlightSettingsSection({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  State<DayHighlightSettingsSection> createState() =>
      _DayHighlightSettingsSectionState();
}

class _DayHighlightSettingsSectionState
    extends State<DayHighlightSettingsSection> {
  var _enabled = true;
  var _seeded = false;
  var _initialEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _enabled = HabitScope.of(context).dayHighlightEnabled;
    _initialEnabled = _enabled;
    _seeded = true;
  }

  bool get _dirty => _enabled != _initialEnabled;

  Future<void> _save() async {
    await HabitScope.of(context).setDayHighlightEnabled(_enabled);
    if (!mounted) return;
    showParentToast(widget.messenger, S.dayHighlightSaved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.dayHighlightHeading,
      hint: S.dayHighlightSettingsHint,
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
                  const Expanded(
                    child: Text(
                      S.dayHighlightEnabled,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    key: const Key('day-highlight-enabled'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-day-highlight'),
              onPressed: _save,
              child: const Text(S.save),
            ),
          ],
        ),
      ),
    );
  }
}
