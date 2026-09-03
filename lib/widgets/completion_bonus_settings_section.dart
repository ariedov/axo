import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';

class CompletionBonusSettingsSection extends StatefulWidget {
  const CompletionBonusSettingsSection({super.key});

  @override
  State<CompletionBonusSettingsSection> createState() =>
      _CompletionBonusSettingsSectionState();
}

class _CompletionBonusSettingsSectionState
    extends State<CompletionBonusSettingsSection> {
  final _amount = TextEditingController();
  var _enabled = true;
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final store = HabitScope.of(context);
    _enabled = store.completionBonusEnabled;
    _amount.text = store.completionBonusPoints.toString();
    _seeded = true;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _toast(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount < 1) {
      _toast(S.invalidCompletionBonus);
      return;
    }
    await HabitScope.of(context)
        .setCompletionBonus(enabled: _enabled, points: amount);
    if (!mounted) return;
    _toast(S.completionBonusSaved);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          S.completionBonus,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        const SizedBox(height: 4),
        const Text(
          S.completionBonusHint,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
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
    );
  }
}
