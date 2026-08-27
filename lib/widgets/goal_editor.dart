import 'package:flutter/material.dart';

import '../data/models.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'task_icons.dart';

class GoalEditResult {
  const GoalEditResult.save(this.goal) : delete = false;
  const GoalEditResult.delete() : goal = null, delete = true;

  final RewardGoal? goal;
  final bool delete;
}

Future<GoalEditResult?> editGoalDialog(
  BuildContext context, {
  RewardGoal? existing,
}) {
  return showDialog<GoalEditResult>(
    context: context,
    builder: (context) => _GoalEditor(existing: existing),
  );
}

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({this.existing});

  final RewardGoal? existing;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final TextEditingController _title;
  late final TextEditingController _cost;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _cost = TextEditingController(text: '${widget.existing?.cost ?? 50}');
    _icon = TaskIcons.canonical(widget.existing?.icon ?? 'gift');
  }

  @override
  void dispose() {
    _title.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    final cost = int.tryParse(_cost.text.trim()) ?? 0;
    if (title.isEmpty || cost <= 0) return;

    Navigator.pop(
      context,
      GoalEditResult.save(
        RewardGoal(
          id: widget.existing?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          cost: cost,
          icon: _icon,
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
            child: Text(widget.existing == null ? S.addGoal : S.editGoal),
          ),
          if (widget.existing != null)
            IconButton(
              tooltip: S.delete,
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.pop(
                context,
                const GoalEditResult.delete(),
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
                controller: _cost,
                label: S.goalCost,
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
