import 'package:flutter/foundation.dart';
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
  bool optional = false,
  bool oneOffDefault = false,
}) {
  return showDialog<TaskEditResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TaskEditor(
      existing: existing,
      optional: existing?.optional ?? optional,
      oneOffDefault: oneOffDefault,
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({
    this.existing,
    this.optional = false,
    this.oneOffDefault = false,
  });

  final HabitTask? existing;
  final bool optional;

  /// New tasks start with no days selected — a one-off for today — instead
  /// of the every-day default used from the parent settings.
  final bool oneOffDefault;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final TextEditingController _title;
  late final TextEditingController _points;
  late String _icon;
  late Set<int> _days;

  static Set<int> _everyDay() => {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  };

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _points = TextEditingController(text: '${widget.existing?.points ?? 10}');
    _icon = TaskIcons.canonical(widget.existing?.icon);
    final existing = widget.existing;
    if (existing == null) {
      _days = widget.oneOffDefault ? <int>{} : _everyDay();
    } else if (existing.todayOnly) {
      _days = <int>{};
    } else {
      _days = existing.weekdays.isEmpty ? _everyDay() : {...existing.weekdays};
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _points.dispose();
    super.dispose();
  }

  List<int> get _sortedDays => _days.toList()..sort();

  /// No day selected means a one-off for today — only allowed from the
  /// main screen.
  bool get _needsDay => _days.isEmpty && !widget.oneOffDefault;

  String get _daysLabel {
    if (_days.isEmpty) {
      return widget.oneOffDefault ? S.onlyToday : S.chooseDay;
    }
    return S.taskDays;
  }

  /// Every day selected is stored as an empty list — the model's
  /// "appears every day" representation.
  List<int> get _savedDays {
    final days = _sortedDays;
    if (days.isEmpty || days.length == DateTime.sunday) return const [];
    return days;
  }

  List<int> get _existingDays {
    final existing = widget.existing;
    if (existing == null || existing.todayOnly) return const [];
    final days = existing.weekdays;
    if (days.isEmpty || days.length == DateTime.sunday) return const [];
    return days;
  }

  bool get _dirty {
    final title = _title.text.trim();
    final points = _points.text.trim();
    final icon = TaskIcons.canonical(widget.existing?.icon);
    final daysChanged = !listEquals(_savedDays, _existingDays);
    if (widget.existing == null) {
      return title.isNotEmpty || points != '10' || _icon != icon || daysChanged;
    }
    return title != widget.existing!.title ||
        points != '${widget.existing!.points}' ||
        _icon != icon ||
        daysChanged;
  }

  Future<void> _tryClose() => closeSettings(context, dirty: _dirty);

  void _save() {
    final title = _title.text.trim();
    final points = int.tryParse(_points.text.trim()) ?? 0;
    if (title.isEmpty || points <= 0 || _needsDay) return;

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
          todayOnly: _days.isEmpty,
          optional: widget.optional,
          weekdays: _savedDays,
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _daysLabel,
                  style: TextStyle(
                    color: _needsDay ? AppColors.pinkDark : AppColors.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var weekday = DateTime.monday;
                      weekday <= DateTime.sunday;
                      weekday++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: weekday == DateTime.sunday ? 0 : 6,
                        ),
                        child: _DayChip(
                          key: Key('task-day-$weekday'),
                          weekday: weekday,
                          selected: _days.contains(weekday),
                          onToggle: () => setState(() {
                            if (_days.contains(weekday)) {
                              _days.remove(weekday);
                            } else {
                              _days.add(weekday);
                            }
                          }),
                        ),
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
                    onPressed: _needsDay ? null : _save,
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

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.weekday,
    required this.selected,
    required this.onToggle,
  });

  final int weekday;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blush : const Color(0xFFFFF3EC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.pink : AppColors.blush,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              S.weekdays[weekday - 1],
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.pinkDark : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
