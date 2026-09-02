import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/game_catalog.dart';
import '../data/models.dart';
import '../screens/bonus_points_screen.dart';
import '../screens/games_screen.dart';
import '../screens/parent_settings_screen.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_card.dart';
import '../widgets/game_plays_banner.dart';
import '../widgets/goal_tile.dart';
import '../widgets/parent_gate.dart';
import '../widgets/points_hero.dart';
import '../widgets/streak_badge.dart';
import '../widgets/strikes_card.dart';
import '../widgets/task_calendar.dart';
import '../widgets/task_editor.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final mood =
        store.celebrating ||
            (store.pendingCount == 0 &&
                store.waitingCount == 0 &&
                store.verifiedCount > 0)
        ? AxolotlMood.celebrate
        : store.waitingCount > 0
        ? AxolotlMood.cheer
        : AxolotlMood.happy;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.peach, Color(0xFFFFE4EC), AppColors.peach],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          AppConfig.appName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        PointsHero(
                          points: store.totalPoints,
                          onLabelTap: () => _openBonus(context),
                        ),
                        AxolotlMascot(mood: mood, size: 128),
                        if (store.streak > 0) ...[
                          const SizedBox(height: 4),
                          StreakBadge(
                            key: const Key('streak-badge'),
                            days: store.streak,
                          ),
                        ],
                        SpeechBubble(
                          text: S.mascotLine(
                            remaining: store.pendingCount,
                            waiting: store.waitingCount,
                            verified: store.verifiedCount,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  if (store.activeGoals.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: S.goals),
                    ),
                    SliverList.builder(
                      itemCount: store.activeGoals.length,
                      itemBuilder: (context, index) {
                        final goal = store.activeGoals[index];
                        return GoalTile(
                          goal: goal,
                          points: store.totalPoints,
                          onSpend: () => _spendGoal(context, goal),
                        );
                      },
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: S.todaysTasks,
                      subtitle: store.todayPossiblePoints == 0
                          ? null
                          : S.todayTaskPoints(
                              store.todayEarnedPoints,
                              store.todayPossiblePoints,
                            ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: store.dailyTasks.length,
                    itemBuilder: (context, index) {
                      final task = store.dailyTasks[index];
                      return TaskTile(
                        task: task,
                        onSubmit: () => store.submit(task.id),
                        onUnsubmit: () => store.unsubmit(task.id),
                        onVerify: () => _verify(context, task),
                      );
                    },
                  ),
                  if (store.pendingCount == 0 && store.waitingCount == 0)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 4, 24, 16),
                        child: Text(
                          S.allDone,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: S.optionalTasks,
                      subtitle: store.extraTasks.isEmpty
                          ? S.optionalTasksHint
                          : store.extraPossiblePoints == 0
                          ? null
                          : S.todayTaskPoints(
                              store.extraEarnedPoints,
                              store.extraPossiblePoints,
                            ),
                      onAdd: () => _addTodayTask(context),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: store.extraTasks.length,
                    itemBuilder: (context, index) {
                      final task = store.extraTasks[index];
                      return TaskTile(
                        task: task,
                        onSubmit: () => store.submit(task.id),
                        onUnsubmit: () => store.unsubmit(task.id),
                        onVerify: () => _verify(context, task),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: S.miniGames,
                          onMore: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const GamesScreen(),
                            ),
                          ),
                          moreTooltip: S.allGames,
                          moreKey: const Key('all-games'),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Text(
                            S.practiceOnly(
                              store.rewardedPlays,
                              store.playLimitMinutes,
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (store.gamesLocked)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                            child: GamePlaysBanner(compact: true),
                          ),
                        GameCardsRow(
                          games: pickRecentMiniGames(store.recentGameIds),
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: _SectionTitle(title: S.calendar),
                    ),
                  ),
                  const SliverToBoxAdapter(child: TaskCalendar()),
                  const SliverToBoxAdapter(
                    child: StrikesCard(key: Key('strikes-card')),
                  ),
                  const SliverToBoxAdapter(child: _ParentSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openBonus(BuildContext context) async {
    if (!await askParent(context, message: S.bonusPointsPrompt)) return;
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const BonusPointsScreen()),
    );
  }

  Future<void> _addTodayTask(BuildContext context) async {
    if (!await askParent(context, message: S.addTodayTaskPrompt)) return;
    if (!context.mounted) return;
    final result = await editTaskDialog(
      context,
      todayOnly: true,
      optional: true,
    );
    final task = result?.task;
    if (task == null || !context.mounted) return;
    await HabitScope.of(context).upsertTask(task);
  }

  Future<void> _spendGoal(BuildContext context, RewardGoal goal) async {
    final store = HabitScope.of(context);
    if (!goal.canAfford(store.totalPoints)) return;
    if (!await askParent(context, message: S.spendGoalPrompt)) return;
    if (!context.mounted) return;
    await store.spendGoal(goal.id);
  }

  Future<void> _verify(BuildContext context, HabitTask task) async {
    final store = HabitScope.of(context);
    await showParentTaskActions(
      context,
      onAward: () {
        HapticFeedback.mediumImpact();
        store.verify(task.id);
      },
      onSendBack: () => store.reject(task.id),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.onAdd,
    this.onMore,
    this.moreTooltip,
    this.moreKey,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onAdd;
  final VoidCallback? onMore;
  final String? moreTooltip;
  final Key? moreKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onAdd != null)
            IconButton(
              key: const Key('add-today-task'),
              tooltip: S.addTask,
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_rounded),
              color: AppColors.pinkDark,
            ),
          if (onMore != null)
            IconButton(
              key: moreKey,
              tooltip: moreTooltip,
              onPressed: onMore,
              icon: const Icon(Icons.chevron_right_rounded),
              color: AppColors.pinkDark,
            ),
        ],
      ),
    );
  }
}

class _ParentSection extends StatelessWidget {
  const _ParentSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: TextButton(
        onPressed: () async {
          if (!await askParent(context, message: S.parentSectionPrompt)) {
            return;
          }
          if (!context.mounted) return;
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const ParentSettingsScreen(),
            ),
          );
        },
        child: const Text(
          S.parentSection,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
