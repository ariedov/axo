import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'settings_sheet.dart';

Future<void> showGameLimitSettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => GameLimitSettingsSection(messenger: messenger),
  );
}

class GameLimitSettingsSection extends StatefulWidget {
  const GameLimitSettingsSection({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  State<GameLimitSettingsSection> createState() =>
      _GameLimitSettingsSectionState();
}

class _GameLimitSettingsSectionState extends State<GameLimitSettingsSection> {
  final _rounds = TextEditingController();
  final _rest = TextEditingController();
  var _enabled = true;
  var _seeded = false;
  var _initialEnabled = true;
  var _initialRounds = '';
  var _initialRest = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final store = HabitScope.of(context);
    _enabled = store.gameLimitEnabled;
    _rounds.text = store.rewardedPlays.toString();
    _rest.text = store.playLimitMinutes.toString();
    _initialEnabled = _enabled;
    _initialRounds = _rounds.text;
    _initialRest = _rest.text;
    _rounds.addListener(_refresh);
    _rest.addListener(_refresh);
    _seeded = true;
  }

  @override
  void dispose() {
    _rounds
      ..removeListener(_refresh)
      ..dispose();
    _rest
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _dirty =>
      _enabled != _initialEnabled ||
      _rounds.text.trim() != _initialRounds ||
      _rest.text.trim() != _initialRest;

  void _toast(String text) => showParentToast(widget.messenger, text);

  Future<void> _save() async {
    final rounds = int.tryParse(_rounds.text.trim()) ?? 0;
    final rest = int.tryParse(_rest.text.trim()) ?? 0;
    if (_enabled && (rounds < 1 || rest < 1)) {
      _toast(S.invalidGameLimit);
      return;
    }
    await HabitScope.of(context).setGameLimit(
      enabled: _enabled,
      rounds: rounds < 1 ? null : rounds,
      restMinutes: rest < 1 ? null : rest,
    );
    if (!mounted) return;
    _toast(S.gameLimitSaved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.gameLimitSettings,
      hint: S.gameLimitSettingsHint,
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
                      S.gameLimitEnabled,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    key: const Key('game-limit-enabled'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              key: const Key('game-limit-rounds'),
              controller: _rounds,
              label: S.gameLimitRounds,
              enabled: _enabled,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            LabeledField(
              key: const Key('game-limit-rest'),
              controller: _rest,
              label: S.gameLimitRest,
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
              key: const Key('save-game-limit'),
              onPressed: _save,
              child: const Text(S.save),
            ),
          ],
        ),
      ),
    );
  }
}
