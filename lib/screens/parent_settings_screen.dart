import 'package:flutter/material.dart';

import '../config.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../widgets/backup_settings_sheet.dart';
import '../widgets/bonus_points_section.dart';
import '../widgets/completion_bonus_settings_section.dart';
import '../widgets/game_limit_settings_section.dart';
import '../widgets/parent_goals_sheet.dart';
import '../widgets/parent_tasks_sheet.dart';
import '../widgets/password_settings_sheet.dart';
import '../widgets/penalty_settings_section.dart';
import '../widgets/settings_tile.dart';

class ParentSettingsScreen extends StatelessWidget {
  const ParentSettingsScreen({super.key});

  void _privacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
  }

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(S.parentSection)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              SettingsTile(
                key: const Key('settings-daily-tasks'),
                title: S.dailyTasks,
                subtitle: S.dailyTasksHint,
                onTap: () => showDailyTasksSheet(context),
              ),
              SettingsTile(
                key: const Key('settings-daily-optional-tasks'),
                title: S.dailyOptionalTasks,
                subtitle: S.dailyOptionalTasksHint,
                onTap: () => showDailyTasksSheet(context, optional: true),
              ),
              SettingsTile(
                key: const Key('settings-goals'),
                title: S.goals,
                subtitle: S.goalsHint,
                onTap: () => showGoalsSettingsSheet(context),
              ),
              SettingsTile(
                key: const Key('settings-bonus-points'),
                title: S.bonusPoints,
                subtitle: S.pointsWord(store.totalPoints),
                onTap: () => showBonusPointsSheet(context),
              ),
              SettingsTile(
                key: const Key('completion-bonus-settings'),
                title: S.completionBonus,
                subtitle: store.completionBonusEnabled
                    ? S.plusPoints(store.completionBonusPoints)
                    : S.off,
                onTap: () => showCompletionBonusSettingsSheet(context),
              ),
              SettingsTile(
                key: const Key('game-limit-settings'),
                title: S.gameLimitSettings,
                subtitle: store.gameLimitEnabled
                    ? '${S.roundsWord(store.rewardedPlays)}, ${S.minutesWord(store.playLimitMinutes)}'
                    : S.off,
                onTap: () => showGameLimitSettingsSheet(context),
              ),
              SettingsTile(
                key: const Key('penalty-settings'),
                title: S.penaltySettings,
                subtitle:
                    '${S.pointsWord(store.penaltyPoints)} · ${S.strikesProgress(store.strikes, AppConfig.strikesToPenalty)}',
                onTap: () => showPenaltySettingsSheet(context),
              ),
              SettingsTile(
                key: const Key('settings-backup'),
                title: S.backup,
                subtitle: S.backupSubtitle,
                onTap: () => showBackupSettingsSheet(context),
              ),
              SettingsTile(
                key: const Key('settings-password'),
                title: S.parentPassword,
                subtitle: store.hasParentPassword ? S.changePassword : S.off,
                onTap: () => showPasswordSettingsSheet(context),
              ),
              TextButton(
                onPressed: () => _privacy(context),
                child: const Text(S.privacy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
