import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/models.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/goal_editor.dart';
import '../widgets/labeled_field.dart';
import '../widgets/task_editor.dart';
import '../widgets/task_icons.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  final _bonus = TextEditingController();
  String? _message;
  var _ok = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    _bonus.dispose();
    super.dispose();
  }

  Future<void> _edit(HabitTask? existing) async {
    final result = await editTaskDialog(context, existing: existing);
    if (result == null || !mounted) return;
    final store = HabitScope.of(context);
    if (result.delete && existing != null) {
      await store.deleteTask(existing.id);
      return;
    }
    if (result.task != null) {
      await store.upsertTask(result.task!);
    }
  }

  Future<void> _editGoal(RewardGoal? existing) async {
    final result = await editGoalDialog(context, existing: existing);
    if (result == null || !mounted) return;
    final store = HabitScope.of(context);
    if (result.delete && existing != null) {
      await store.deleteGoal(existing.id);
      return;
    }
    if (result.goal != null) {
      await store.upsertGoal(result.goal!);
    }
  }

  Future<void> _spendGoal(RewardGoal goal) async {
    final spent = await HabitScope.of(context).spendGoal(
      goal.id,
      celebrate: false,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(spent ? S.spentGoal : S.notEnoughPoints)),
    );
  }

  Future<void> _adjustPoints(int delta) async {
    final applied = await HabitScope.of(context).adjustPoints(delta);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied == 0 ? S.noPointsToRemove : S.pointsAdjusted(applied),
        ),
      ),
    );
  }

  Future<void> _adjustCustom(bool add) async {
    final amount = int.tryParse(_bonus.text.trim()) ?? 0;
    if (amount <= 0) return;
    await _adjustPoints(add ? amount : -amount);
  }

  Future<void> _savePassword() async {
    final next = _next.text.trim();
    if (next.length < AppConfig.minPasswordLength) {
      setState(() {
        _ok = false;
        _message = S.passwordTooShort;
      });
      return;
    }
    if (next != _repeat.text.trim()) {
      setState(() {
        _ok = false;
        _message = S.passwordsDontMatch;
      });
      return;
    }

    final changed = await HabitScope.of(context).changePassword(
      current: _current.text,
      next: next,
    );
    setState(() {
      _ok = changed;
      _message = changed ? S.passwordChanged : S.wrongPassword;
    });
    if (changed) {
      _current.clear();
      _next.clear();
      _repeat.clear();
    }
  }

  static Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOut.transform(animation.value);
        return Transform.scale(
          scale: 1 + (0.02 * t),
          child: Material(
            elevation: 8 * t,
            color: Colors.transparent,
            shadowColor: AppColors.pink.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final daily = store.dailyTasks;

    return Scaffold(
      appBar: AppBar(title: const Text(S.parentSection)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              S.dailyTasks,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: S.addTask,
                            onPressed: () => _edit(null),
                            icon: const Icon(Icons.add_circle_rounded),
                            color: AppColors.pinkDark,
                          ),
                        ],
                      ),
                      const Text(
                        S.dailyTasksHint,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        S.reorderTasksHint,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverReorderableList(
                  itemCount: daily.length,
                  onReorderItem: store.reorderDailyTasks,
                  proxyDecorator: _proxyDecorator,
                  itemBuilder: (context, index) {
                    final task = daily[index];
                    return Padding(
                      key: ValueKey(task.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: _DailyTaskRow(
                          task: task,
                          index: index,
                          onTap: () => _edit(task),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              S.goals,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: S.addGoal,
                            onPressed: () => _editGoal(null),
                            icon: const Icon(Icons.add_circle_rounded),
                            color: AppColors.pinkDark,
                          ),
                        ],
                      ),
                      const Text(
                        S.goalsHint,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (store.goals.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            S.noGoalsYet,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverReorderableList(
                  itemCount: store.goals.length,
                  onReorderItem: store.reorderGoals,
                  proxyDecorator: _proxyDecorator,
                  itemBuilder: (context, index) {
                    final goal = store.goals[index];
                    return Padding(
                      key: ValueKey(goal.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: _GoalRow(
                          goal: goal,
                          index: index,
                          points: store.totalPoints,
                          onTap: () => _editGoal(goal),
                          onSpend: () => _spendGoal(goal),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _BonusPointsSection(
                    points: store.totalPoints,
                    amount: _bonus,
                    onCustom: _adjustCustom,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        S.changePassword,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        controller: _current,
                        label: S.currentPassword,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      LabeledField(
                        controller: _next,
                        label: S.newPassword,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      LabeledField(
                        controller: _repeat,
                        label: S.repeatPassword,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _savePassword(),
                      ),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _message!,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _ok
                                  ? AppColors.tealDark
                                  : AppColors.pinkDark,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _savePassword,
                        child: const Text(S.save),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              title: const Text(S.privacy),
                              content: const Text(S.privacyBody),
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(S.ok),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(S.privacy),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BonusPointsSection extends StatefulWidget {
  const _BonusPointsSection({
    required this.points,
    required this.amount,
    required this.onCustom,
  });

  final int points;
  final TextEditingController amount;
  final ValueChanged<bool> onCustom;

  @override
  State<_BonusPointsSection> createState() => _BonusPointsSectionState();
}

class _BonusPointsSectionState extends State<_BonusPointsSection> {
  @override
  void initState() {
    super.initState();
    widget.amount.addListener(_onAmountChanged);
  }

  @override
  void didUpdateWidget(covariant _BonusPointsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      oldWidget.amount.removeListener(_onAmountChanged);
      widget.amount.addListener(_onAmountChanged);
    }
  }

  @override
  void dispose() {
    widget.amount.removeListener(_onAmountChanged);
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  bool get _canAdjust {
    final amount = int.tryParse(widget.amount.text.trim()) ?? 0;
    return amount > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          S.bonusPoints,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          S.bonusPointsHint,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          S.pointsNow(widget.points),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.pinkDark,
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          key: const Key('bonus-amount'),
          controller: widget.amount,
          label: S.pointsAmount,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_canAdjust) widget.onCustom(true);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _canAdjust ? () => widget.onCustom(false) : null,
                child: const Text(S.removePoints),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _canAdjust ? () => widget.onCustom(true) : null,
                child: const Text(S.addPoints),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyTaskRow extends StatelessWidget {
  const _DailyTaskRow({
    required this.task,
    required this.index,
    required this.onTap,
  });

  final HabitTask task;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.blush, width: 2),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_handle_rounded, color: AppColors.muted),
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: TaskGlyph(task.icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      S.plusPoints(task.points),
                      style: const TextStyle(
                        color: AppColors.pinkDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.index,
    required this.points,
    required this.onTap,
    required this.onSpend,
  });

  final RewardGoal goal;
  final int index;
  final int points;
  final VoidCallback onTap;
  final VoidCallback onSpend;

  @override
  Widget build(BuildContext context) {
    final ready = goal.canAfford(points);

    return Material(
      color: ready ? const Color(0xFFFFF6D4) : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: ready ? AppColors.gold : AppColors.blush,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_handle_rounded, color: AppColors.muted),
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: TaskGlyph(
                  goal.icon,
                  size: 22,
                  color: ready ? AppColors.goldDeep : AppColors.pinkDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      S.goalProgress(points, goal.cost),
                      style: TextStyle(
                        color: ready ? AppColors.goldDeep : AppColors.pinkDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (ready)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilledButton(
                    onPressed: onSpend,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldDeep,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(S.spendGoal),
                  ),
                ),
              const Icon(Icons.edit_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

