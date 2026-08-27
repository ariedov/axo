import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/models.dart';
import '../screens/english_screen.dart';
import '../screens/parent_settings_screen.dart';
import '../screens/spelling_screen.dart';
import '../screens/times_tables_screen.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/goal_tile.dart';
import '../widgets/parent_gate.dart';
import '../widgets/points_hero.dart';
import '../widgets/task_calendar.dart';
import '../widgets/task_editor.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final mood = store.celebrating ||
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
                        PointsHero(points: store.totalPoints),
                        AxolotlMascot(mood: mood, size: store.celebrating ? 150 : 128),
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
                  if (store.goals.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: S.goals),
                    ),
                    SliverList.builder(
                      itemCount: store.goals.length,
                      itemBuilder: (context, index) {
                        final goal = store.goals[index];
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
                      onAdd: () => _addTodayTask(context),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: store.tasks.length,
                    itemBuilder: (context, index) {
                      final task = store.tasks[index];
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
                  const SliverToBoxAdapter(child: _GamesSection()),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: _SectionTitle(title: S.calendar),
                    ),
                  ),
                  const SliverToBoxAdapter(child: TaskCalendar()),
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

  Future<void> _addTodayTask(BuildContext context) async {
    if (!await askParent(context, message: S.addTodayTaskPrompt)) return;
    if (!context.mounted) return;
    final result = await editTaskDialog(context, todayOnly: true);
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
  const _SectionTitle({required this.title, this.onAdd});

  final String title;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
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
        ],
      ),
    );
  }
}

class _GamesSection extends StatelessWidget {
  const _GamesSection();

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.miniGames,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            S.practiceOnly,
            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 168,
            child: Row(
              children: [
                Expanded(
                  child: _GameCard(
                    icon: Icons.calculate_rounded,
                    title: S.timesTables,
                    subtitle: S.timesTablesHint,
                    color: AppColors.teal,
                    used: store.playsUsed(AppConfig.timesTablesGame),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const TimesTablesScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GameCard(
                    icon: Icons.spellcheck_rounded,
                    title: S.spelling,
                    subtitle: S.spellingHint,
                    color: AppColors.pink,
                    used: store.playsUsed(AppConfig.spellingGame),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SpellingScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GameCard(
                    icon: Icons.translate_rounded,
                    title: S.english,
                    subtitle: S.englishHint,
                    color: AppColors.goldDeep,
                    used: store.playsUsed(AppConfig.englishGame),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const EnglishScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.used,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: used < AppConfig.rewardedPlaysPerGame
                          ? AppColors.goldDeep
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      S.gameRoundsProgress(used, AppConfig.rewardedPlaysPerGame),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: used < AppConfig.rewardedPlaysPerGame
                            ? AppColors.goldDeep
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
