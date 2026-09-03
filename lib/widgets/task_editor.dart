import 'package:flutter/material.dart';

import '../data/models.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'settings_sheet.dart';
import 'task_icons.dart';

class TaskEditResult {
  const TaskEditResult.save(this.task) : delete = false;
  const TaskEditResult.delete() : task = null, delete = true;

  final HabitTask? task;
  final bool delete;
}

Future<TaskEditResult?> editTaskDialog(
  BuildContext context, {
  HabitTask? existing,
  bool todayOnly = false,
  bool optional = false,
}) {
  return showDialog<TaskEditResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TaskEditor(
      existing: existing,
      todayOnly: existing?.todayOnly ?? todayOnly,
      optional: existing?.optional ?? optional,
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({
    this.existing,
    this.todayOnly = false,
    this.optional = false,
  });

  final HabitTask? existing;
  final bool todayOnly;
  final bool optional;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final TextEditingController _title;
  late final TextEditingController _points;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _points = TextEditingController(text: '${widget.existing?.points ?? 10}');
    _icon = TaskIcons.canonical(widget.existing?.icon);
  }

  @override
  void dispose() {
    _title.dispose();
    _points.dispose();
    super.dispose();
  }

  bool get _dirty {
    final title = _title.text.trim();
    final points = _points.text.trim();
    final icon = TaskIcons.canonical(widget.existing?.icon);
    if (widget.existing == null) {
      return title.isNotEmpty || points != '10' || _icon != icon;
    }
    return title != widget.existing!.title ||
        points != '${widget.existing!.points}' ||
        _icon != icon;
  }

  Future<void> _tryClose() => closeSettings(context, dirty: _dirty);

  void _save() {
    final title = _title.text.trim();
    final points = int.tryParse(_points.text.trim()) ?? 0;
    if (title.isEmpty || points <= 0) return;

    Navigator.pop(
      context,
      TaskEditResult.save(
        HabitTask(
          id: widget.existing?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          points: points,
          icon: _icon,
          status: widget.existing?.status ?? TaskStatus.pending,
          todayOnly: widget.todayOnly,
          optional: widget.optional,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Expanded(
            child: Text(widget.existing == null ? S.addTask : S.editTask),
          ),
          if (widget.existing != null)
            IconButton(
              tooltip: S.delete,
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.pop(
                context,
                const TaskEditResult.delete(),
              ),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField(
                controller: _title,
                label: S.taskTitle,
              ),
              const SizedBox(height: 12),
              LabeledField(
                controller: _points,
                label: S.taskPoints,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
                children: [
                  for (final entry in TaskIcons.choices.entries)
                    Material(
                      color: _icon == entry.key
                          ? AppColors.blush
                          : const Color(0xFFFFF3EC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _icon == entry.key
                              ? AppColors.pink
                              : AppColors.blush,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _icon = entry.key),
                        borderRadius: BorderRadius.circular(16),
                        child: Icon(entry.value, color: AppColors.pinkDark),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _tryClose,
                    child: const Text(S.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text(S.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
