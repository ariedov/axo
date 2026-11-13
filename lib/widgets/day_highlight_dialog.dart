import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/today.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import 'axolotl_mascot.dart';
import 'badge_award_dialog.dart';
import 'labeled_field.dart';

/// Asks what good thing happened. Returns the trimmed note, or null if skipped.
Future<String?> showDayHighlightDialog(
  BuildContext context, {
  required bool today,
  String? initialNote,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _DayHighlightDialog(today: today, initialNote: initialNote),
  );
}

/// Writes (or edits) today's good thing and celebrates any badge it earned.
Future<void> recordGoodThing(BuildContext context) async {
  final store = HabitScope.of(context);
  final day = todayStamp(store.now());
  final note = await showDayHighlightDialog(
    context,
    today: true,
    initialNote: store.highlightOn(day),
  );
  if (note == null || !context.mounted) return;
  await store.saveDayHighlight(day, note);
  if (!context.mounted) return;
  final awards = await store.awardNewBadges();
  if (awards.isEmpty || !context.mounted) return;
  await showBadgeAwardDialog(context, awards);
}

class _DayHighlightDialog extends StatefulWidget {
  const _DayHighlightDialog({required this.today, this.initialNote});

  final bool today;
  final String? initialNote;

  @override
  State<_DayHighlightDialog> createState() => _DayHighlightDialogState();
}

class _DayHighlightDialogState extends State<_DayHighlightDialog> {
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialNote;
    if (initial != null && initial.isNotEmpty) {
      _note.text = initial;
      _note.selection = TextSelection.collapsed(offset: initial.length);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => _note.text.trim().isNotEmpty;

  void _save() {
    final note = _note.text.trim();
    if (note.isEmpty) return;
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('day-highlight-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AxolotlMascot(mood: AxolotlMood.happy, size: 96),
            const SizedBox(height: 8),
            LabeledField(
              key: const Key('day-highlight-field'),
              controller: _note,
              label: widget.today ? S.dayHighlightToday : S.dayHighlightThatDay,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 3,
              autofocus: true,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  AppConfig.dayHighlightMaxLength,
                ),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('day-highlight-skip'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.initialNote == null
                            ? S.dayHighlightSkip
                            : S.cancel,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('day-highlight-save'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _canSave ? _save : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(S.save, maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
