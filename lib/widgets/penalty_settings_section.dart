import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'settings_sheet.dart';

Future<void> showPenaltySettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => PenaltySettingsSection(messenger: messenger),
  );
}

class PenaltySettingsSection extends StatefulWidget {
  const PenaltySettingsSection({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  State<PenaltySettingsSection> createState() => _PenaltySettingsSectionState();
}

class _PenaltySettingsSectionState extends State<PenaltySettingsSection> {
  final _amount = TextEditingController();
  var _seeded = false;
  var _initialAmount = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _amount.text = HabitScope.of(context).penaltyPoints.toString();
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

  bool get _dirty => _amount.text.trim() != _initialAmount;

  void _toast(String text) => showParentToast(widget.messenger, text);

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount < 1) {
      _toast(S.invalidPenalty);
      return;
    }
    await HabitScope.of(context).setPenaltyPoints(amount);
    if (!mounted) return;
    _toast(S.penaltySaved);
    Navigator.pop(context);
  }

  Future<void> _clear() async {
    await HabitScope.of(context).clearStrikes();
    if (!mounted) return;
    _toast(S.strikesCleared);
  }

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    return SettingsSheetScaffold(
      title: S.penaltySettings,
      hint: S.penaltySettingsHint,
      dirty: _dirty,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${S.strikes}: ${S.strikesProgress(store.strikes, AppConfig.strikesToPenalty)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.pinkDark,
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              key: const Key('penalty-amount'),
              controller: _amount,
              label: S.penaltyPoints,
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
              key: const Key('save-penalty'),
              onPressed: _save,
              child: const Text(S.save),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('clear-strikes'),
              onPressed: store.strikes > 0 ? _clear : null,
              child: const Text(S.clearStrikes),
            ),
          ],
        ),
      ),
    );
  }
}
