import 'package:flutter/material.dart';

import '../data/models.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
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
}) {
  return showDialog<TaskEditResult>(
    context: context,
    builder: (context) => _TaskEditor(existing: existing),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({this.existing});

  final HabitTask? existing;

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
                    onPressed: () => Navigator.pop(context),
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
