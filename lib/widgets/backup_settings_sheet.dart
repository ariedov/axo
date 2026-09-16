import 'package:flutter/material.dart';

import '../data/backup_share.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import 'settings_sheet.dart';

Future<void> showBackupSettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => BackupSettingsSheet(messenger: messenger),
  );
}

Future<void> showImportResultDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(title),
      content: Text(body),
      actions: [
        FilledButton(
          key: const Key('import-result-ok'),
          onPressed: () => Navigator.pop(context),
          child: const Text(S.ok),
        ),
      ],
    ),
  );
}

Future<bool> showImportReplaceDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(S.importReplaceTitle),
      content: const Text(S.importReplaceBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(S.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(S.importConfirm),
        ),
      ],
    ),
  );
  return confirmed == true;
}

class BackupSettingsSheet extends StatelessWidget {
  const BackupSettingsSheet({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  Future<void> _export(BuildContext context) async {
    try {
      final saved = await saveBackup(HabitScope.of(context).exportBackup());
      if (!saved) return;
      showParentToast(messenger, S.exportDone);
    } catch (_) {
      showParentToast(messenger, S.exportFailed);
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final confirmed = await showImportReplaceDialog(context);
      if (!confirmed || !context.mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;
      final snapshot = await pickBackup();
      if (snapshot == null || !context.mounted) return;
      await HabitScope.of(context).importBackup(snapshot);
      if (!context.mounted) return;
      await showImportResultDialog(
        context,
        title: S.importSuccessTitle,
        body: S.importSuccessBody,
      );
    } on FormatException {
      if (!context.mounted) return;
      await showImportResultDialog(
        context,
        title: S.importErrorTitle,
        body: S.importInvalid,
      );
    } catch (_) {
      if (!context.mounted) return;
      await showImportResultDialog(
        context,
        title: S.importErrorTitle,
        body: S.importErrorBody,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.backup,
      hint: S.backupHint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            key: const Key('export-backup'),
            onPressed: () => _export(context),
            child: const Text(S.exportBackup),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('import-backup'),
            onPressed: () => _import(context),
            child: const Text(S.importBackup),
          ),
        ],
      ),
    );
  }
}
