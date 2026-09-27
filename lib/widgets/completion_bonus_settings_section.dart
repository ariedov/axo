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
  final _streakMax = TextEditingController();
  var _enabled = true;
  var _streakEnabled = true;
  var _seeded = false;
  var _initialEnabled = true;
  var _initialAmount = '';
  var _initialStreakEnabled = true;
  var _initialStreakMax = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final store = HabitScope.of(context);
    _enabled = store.completionBonusEnabled;
    _streakEnabled = store.streakBonusEnabled;
    _amount.text = store.completionBonusPoints.toString();
    _streakMax.text = store.streakBonusMaxPoints.toString();
    _initialEnabled = _enabled;
    _initialAmount = _amount.text;
    _initialStreakEnabled = _streakEnabled;
    _initialStreakMax = _streakMax.text;
    _amount.addListener(_refresh);
    _streakMax.addListener(_refresh);
    _seeded = true;
  }

  @override
  void dispose() {
    _amount
      ..removeListener(_refresh)
      ..dispose();
    _streakMax
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _dirty =>
      _enabled != _initialEnabled ||
      _amount.text.trim() != _initialAmount ||
      _streakEnabled != _initialStreakEnabled ||
      _streakMax.text.trim() != _initialStreakMax;

  void _toast(String text) => showParentToast(widget.messenger, text);

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    final streakMax = int.tryParse(_streakMax.text.trim()) ?? 0;
    if (_enabled && amount < 1) {
      _toast(S.invalidCompletionBonus);
      return;
    }
    if (_streakEnabled && streakMax < 1) {
      _toast(S.invalidCompletionBonus);
      return;
    }
    await HabitScope.of(context).setCompletionBonus(
      enabled: _enabled,
      points: amount < 1 ? null : amount,
      streakEnabled: _streakEnabled,
      streakMaxPoints: streakMax < 1 ? null : streakMax,
    );
    if (!mounted) return;
    _toast(S.completionBonusSaved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.completionBonus,
      dirty: _dirty,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BonusBlock(
              title: S.completionBonusDaily,
              hint: S.completionBonusHint,
              label: S.completionBonusEnabled,
              enabled: _enabled,
              switchKey: const Key('completion-bonus-enabled'),
              onChanged: (value) => setState(() => _enabled = value),
              field: LabeledField(
                key: const Key('completion-bonus-amount'),
                controller: _amount,
                label: S.completionBonusPoints,
                enabled: _enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: 28),
            _BonusBlock(
              title: S.streakBonusSection,
              hint: S.streakBonusHint,
              label: S.streakBonusEnabled,
              enabled: _streakEnabled,
              switchKey: const Key('streak-bonus-enabled'),
              onChanged: (value) => setState(() => _streakEnabled = value),
              field: LabeledField(
                key: const Key('streak-bonus-max'),
                controller: _streakMax,
                label: S.streakBonusMax,
                enabled: _streakEnabled,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: 28),
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

class _BonusBlock extends StatelessWidget {
  const _BonusBlock({
    required this.title,
    required this.hint,
    required this.label,
    required this.enabled,
    required this.switchKey,
    required this.onChanged,
    required this.field,
  });

  final String title;
  final String hint;
  final String label;
  final bool enabled;
  final Key switchKey;
  final ValueChanged<bool> onChanged;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.pinkDark,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hint,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.blush, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Switch(key: switchKey, value: enabled, onChanged: onChanged),
            ],
          ),
        ),
        const SizedBox(height: 12),
        field,
      ],
    );
  }
}
