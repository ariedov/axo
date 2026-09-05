import 'package:flutter/material.dart';

import '../config.dart';
import '../data/models.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/goal_editor.dart';
import '../widgets/labeled_field.dart';
import '../widgets/task_icons.dart';

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
  var _step = 0;
  var _skippedPassword = false;
  String? _error;
  RewardGoal? _goal;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    _points.dispose();
    super.dispose();
  }

  void _back() {
    if (_step == 0) return;
    setState(() {
      _step -= 1;
      _error = null;
    });
  }

  void _nextFromWelcome() {
    setState(() => _step = 1);
  }

  void _nextFromPassword({bool skipPassword = false}) {
    final password = _password.text.trim();
    final repeat = _repeat.text.trim();
    final pointsText = _points.text.trim();
    final points =
        int.tryParse(pointsText) ??
        (pointsText.isEmpty ? AppConfig.defaultStartingPoints : null);
    if (!skipPassword) {
      if (password.length < AppConfig.minPasswordLength) {
        setState(() => _error = S.passwordTooShort);
        return;
      }
      if (password != repeat) {
        setState(() => _error = S.passwordsDontMatch);
        return;
      }
    }
    if (points == null || points < 0) {
      setState(() => _error = S.invalidPoints);
      return;
    }
    setState(() {
      _error = null;
      _skippedPassword = skipPassword;
      _step = 2;
    });
  }

  Future<void> _addGoal() async {
    final result = await editGoalDialog(context, existing: _goal);
    if (result == null || !mounted) return;
    if (result.delete) {
      setState(() => _goal = null);
      return;
    }
    if (result.goal != null) setState(() => _goal = result.goal);
  }

  Future<void> _finish() async {
    final points =
        int.tryParse(_points.text.trim()) ?? AppConfig.defaultStartingPoints;
    await HabitScope.of(context).completeOnboarding(
      password: _skippedPassword ? '' : _password.text.trim(),
      startingPoints: points,
      goal: _goal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
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
                child: Column(
                  children: [
                    _TopBar(step: _step, onBack: _step > 0 ? _back : null),
                    Expanded(
                      child: switch (_step) {
                        0 => _WelcomePage(onNext: _nextFromWelcome),
                        1 => _PasswordPage(
                          password: _password,
                          repeat: _repeat,
                          points: _points,
                          error: _error,
                          onChanged: () {
                            if (_error != null) setState(() => _error = null);
                          },
                          onNext: () => _nextFromPassword(),
                          onSkip: () => _nextFromPassword(skipPassword: true),
                        ),
                        2 => _GoalPage(
                          goal: _goal,
                          points:
                              int.tryParse(_points.text.trim()) ??
                              AppConfig.defaultStartingPoints,
                          onAdd: _addGoal,
                          onNext: () => setState(() => _step = 3),
                        ),
                        _ => _DonePage(onDone: _finish),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.ink,
                  ),
          ),
          Expanded(
            child: Text(
              AppConfig.appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: i == step ? 18 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == step ? AppColors.pinkDark : AppColors.blush,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      step: 0,
      mood: AxolotlMood.happy,
      bubble: S.onboardingHello,
      children: const [
        Text(
          S.onboardingParentsBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          S.onboardingPrivacy,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
      action: FilledButton(
        onPressed: onNext,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(S.next),
        ),
      ),
    );
  }
}

class _PasswordPage extends StatelessWidget {
  const _PasswordPage({
    required this.password,
    required this.repeat,
    required this.points,
    required this.error,
    required this.onChanged,
    required this.onNext,
    required this.onSkip,
  });

  final TextEditingController password;
  final TextEditingController repeat;
  final TextEditingController points;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      step: 1,
      mood: AxolotlMood.happy,
      bubble: S.onboardingHello,
      children: [
        const Text(
          S.onboardingBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 16),
        LabeledField(
          controller: password,
          label: S.choosePassword,
          obscureText: true,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        LabeledField(
          controller: repeat,
          label: S.repeatPassword,
          obscureText: true,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onNext(),
        ),
        const SizedBox(height: 12),
        LabeledField(
          controller: points,
          label: S.startingPoints,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onNext(),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.pinkDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: onNext,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(S.next),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('onboarding-skip-password'),
            onPressed: onSkip,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(S.skipPassword),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.goal,
    required this.points,
    required this.onAdd,
    required this.onNext,
  });

  final RewardGoal? goal;
  final int points;
  final VoidCallback onAdd;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      step: 2,
      mood: AxolotlMood.cheer,
      bubble: S.onboardingGoalHello,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                S.onboardingGoalBody,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            IconButton(
              key: const Key('onboarding-add-goal'),
              tooltip: S.addGoal,
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_rounded, size: 36),
              color: AppColors.pinkDark,
            ),
          ],
        ),
        if (goal != null) ...[
          const SizedBox(height: 12),
          _GoalPreview(goal: goal!, points: points, onEdit: onAdd),
        ],
      ],
      action: FilledButton(
        onPressed: onNext,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(S.next),
        ),
      ),
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      step: 3,
      mood: AxolotlMood.celebrate,
      bubble: S.onboardingDoneHello,
      children: const [
        Text(
          S.onboardingDoneBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ],
      action: FilledButton(
        onPressed: onDone,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(S.understood),
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.step,
    required this.mood,
    required this.bubble,
    required this.children,
    required this.action,
  });

  final int step;
  final AxolotlMood mood;
  final String bubble;
  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            children: [
              AxolotlMascot(mood: mood, size: 110, animate: false),
              SpeechBubble(text: bubble),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Dots(step: step),
              const SizedBox(height: 16),
              action,
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalPreview extends StatelessWidget {
  const _GoalPreview({
    required this.goal,
    required this.points,
    required this.onEdit,
  });

  final RewardGoal goal;
  final int points;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.blush, width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: TaskGlyph(goal.icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      S.goalProgress(points, goal.cost),
                      style: const TextStyle(
                        color: AppColors.pinkDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
