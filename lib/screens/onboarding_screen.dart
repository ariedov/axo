import 'package:flutter/material.dart';

import '../config.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/labeled_field.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  final _points = TextEditingController(
    text: '${AppConfig.defaultStartingPoints}',
  );
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _password.text.trim();
    final repeat = _repeat.text.trim();
    final pointsText = _points.text.trim();
    final points = int.tryParse(pointsText) ??
        (pointsText.isEmpty ? AppConfig.defaultStartingPoints : null);
    if (password.length < AppConfig.minPasswordLength) {
      setState(() => _error = S.passwordTooShort);
      return;
    }
    if (password != repeat) {
      setState(() => _error = S.passwordsDontMatch);
      return;
    }
    if (points == null || points < 0) {
      setState(() => _error = S.invalidPoints);
      return;
    }
    await HabitScope.of(context).completeOnboarding(
      password: password,
      startingPoints: points,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.peach, Color(0xFFFFE4EC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(
                    AppConfig.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const AxolotlMascot(
                    mood: AxolotlMood.happy,
                    size: 110,
                    animate: false,
                  ),
                  const SpeechBubble(text: S.onboardingHello),
                  const SizedBox(height: 12),
                  const Text(
                    S.onboardingBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    S.onboardingPrivacy,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    controller: _password,
                    label: S.choosePassword,
                    obscureText: true,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    controller: _repeat,
                    label: S.repeatPassword,
                    obscureText: true,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    controller: _points,
                    label: S.startingPoints,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.pinkDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(S.letsGo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
