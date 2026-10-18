import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../strings.dart';
import 'axolotl_mascot.dart';
import 'labeled_field.dart';

/// Asks what good thing happened. Returns the trimmed note, or null if skipped.
Future<String?> showDayHighlightDialog(
  BuildContext context, {
  required bool today,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DayHighlightDialog(today: today),
  );
}

class _DayHighlightDialog extends StatefulWidget {
  const _DayHighlightDialog({required this.today});

  final bool today;

  @override
  State<_DayHighlightDialog> createState() => _DayHighlightDialogState();
}

class _DayHighlightDialogState extends State<_DayHighlightDialog> {
  final _note = TextEditingController();

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
                    onPressed: () => Navigator.pop(context),
                    child: const Text(S.dayHighlightSkip),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('day-highlight-save'),
                    onPressed: _canSave ? _save : null,
                    child: const Text(S.save),
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
