import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'settings_sheet.dart';

Future<void> showCompletionBonusSettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => CompletionBonusSettingsSection(messenger: messenger),
  );
}

class CompletionBonusSettingsSection extends StatefulWidget {
  const CompletionBonusSettingsSection({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  State<CompletionBonusSettingsSection> createState() =>
      _CompletionBonusSettingsSectionState();
}

class _CompletionBonusSettingsSectionState
    extends State<CompletionBonusSettingsSection> {
  final _amount = TextEditingController();
  var _enabled = true;
  var _seeded = false;
  var _initialEnabled = true;
  var _initialAmount = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final store = HabitScope.of(context);
    _enabled = store.completionBonusEnabled;
    _amount.text = store.completionBonusPoints.toString();
    _initialEnabled = _enabled;
    _initialAmount = _amount.text;
    _amount.addListener(_refresh);
    _seeded = true;
  }

  @override
  void dispose() {
    _amount
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _dirty =>
      _enabled != _initialEnabled || _amount.text.trim() != _initialAmount;

  void _toast(String text) => showParentToast(widget.messenger, text);

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (_enabled && amount < 1) {
      _toast(S.invalidCompletionBonus);
      return;
    }
    await HabitScope.of(context).setCompletionBonus(
      enabled: _enabled,
      points: amount < 1 ? null : amount,
    );
    if (!mounted) return;
    _toast(S.completionBonusSaved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.completionBonus,
      hint: S.completionBonusHint,
      dirty: _dirty,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.blush, width: 2),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      S.completionBonusEnabled,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  Switch(
                    key: const Key('completion-bonus-enabled'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              key: const Key('completion-bonus-amount'),
              controller: _amount,
              label: S.completionBonusPoints,
              enabled: _enabled,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-completion-bonus'),
              onPressed: _save,
              child: const Text(S.save),
            ),
          ],
        ),
      ),
    );
  }
}
