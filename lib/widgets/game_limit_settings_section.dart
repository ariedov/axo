import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';

class GameLimitSettingsSection extends StatefulWidget {
  const GameLimitSettingsSection({super.key});

  @override
  State<GameLimitSettingsSection> createState() =>
      _GameLimitSettingsSectionState();
}

class _GameLimitSettingsSectionState extends State<GameLimitSettingsSection> {
  final _rounds = TextEditingController();
  final _rest = TextEditingController();
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final store = HabitScope.of(context);
    _rounds.text = store.rewardedPlays.toString();
    _rest.text = store.playLimitMinutes.toString();
    _seeded = true;
  }

  @override
  void dispose() {
    _rounds.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _toast(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final rounds = int.tryParse(_rounds.text.trim()) ?? 0;
    final rest = int.tryParse(_rest.text.trim()) ?? 0;
    if (rounds < 1 || rest < 1) {
      _toast(S.invalidGameLimit);
      return;
    }
    await HabitScope.of(context)
        .setGameLimit(rounds: rounds, restMinutes: rest);
    if (!mounted) return;
    _toast(S.gameLimitSaved);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          S.gameLimitSettings,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        const SizedBox(height: 4),
        const Text(
          S.gameLimitSettingsHint,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LabeledField(
          key: const Key('game-limit-rounds'),
          controller: _rounds,
          label: S.gameLimitRounds,
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
    );
  }
}
