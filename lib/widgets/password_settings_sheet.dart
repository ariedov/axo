import 'package:flutter/material.dart';

import '../config.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'settings_sheet.dart';

Future<void> showPasswordSettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => PasswordSettingsSheet(messenger: messenger),
  );
}

class PasswordSettingsSheet extends StatefulWidget {
  const PasswordSettingsSheet({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  State<PasswordSettingsSheet> createState() => _PasswordSettingsSheetState();
}

class _PasswordSettingsSheetState extends State<PasswordSettingsSheet> {
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  String? _message;
  var _ok = false;
  var _enabled = true;
  var _hadPassword = true;
  var _seeded = false;

  @override
  void initState() {
    super.initState();
    _next.addListener(_refresh);
    _repeat.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _hadPassword = HabitScope.of(context).hasParentPassword;
    _enabled = _hadPassword;
    _seeded = true;
  }

  @override
  void dispose() {
    _next
      ..removeListener(_refresh)
      ..dispose();
    _repeat
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _dirty =>
      _enabled != _hadPassword ||
      _next.text.isNotEmpty ||
      _repeat.text.isNotEmpty;

  Future<void> _save() async {
    final store = HabitScope.of(context);
    if (!_enabled) {
      if (_hadPassword) await store.setParentPassword('');
      if (!mounted) return;
      showParentToast(widget.messenger, S.passwordOff);
      Navigator.pop(context);
      return;
    }

    final next = _next.text.trim();
    if (_hadPassword && next.isEmpty && _repeat.text.isEmpty) {
      Navigator.pop(context);
      return;
    }
    if (next.length < AppConfig.minPasswordLength) {
      setState(() {
        _ok = false;
        _message = S.passwordTooShort;
      });
      return;
    }
    if (next != _repeat.text.trim()) {
      setState(() {
        _ok = false;
        _message = S.passwordsDontMatch;
      });
      return;
    }

    await store.setParentPassword(next);
    if (!mounted) return;
    showParentToast(widget.messenger, S.passwordChanged);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.parentPassword,
      hint: S.parentPasswordHint,
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
                      S.passwordEnabled,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    key: const Key('password-enabled'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                ],
              ),
            ),
            if (_enabled) ...[
              const SizedBox(height: 12),
              LabeledField(
                key: const Key('password-next'),
                controller: _next,
                label: _hadPassword ? S.newPassword : S.choosePassword,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              LabeledField(
                key: const Key('password-repeat'),
                controller: _repeat,
                label: S.repeatPassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
            ],
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _message!,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _ok ? AppColors.tealDark : AppColors.pinkDark,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('save-password'),
              onPressed: _save,
              child: const Text(S.save),
            ),
          ],
        ),
      ),
    );
  }
}
