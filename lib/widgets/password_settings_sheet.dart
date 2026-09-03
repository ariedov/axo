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
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  String? _message;
  var _ok = false;

  @override
  void initState() {
    super.initState();
    _current.addListener(_refresh);
    _next.addListener(_refresh);
    _repeat.addListener(_refresh);
  }

  @override
  void dispose() {
    _current
      ..removeListener(_refresh)
      ..dispose();
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
      _current.text.isNotEmpty ||
      _next.text.isNotEmpty ||
      _repeat.text.isNotEmpty;

  Future<void> _save() async {
    final next = _next.text.trim();
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

    final changed = await HabitScope.of(context).changePassword(
      current: _current.text,
      next: next,
    );
    if (!mounted) return;
    if (!changed) {
      setState(() {
        _ok = false;
        _message = S.wrongPassword;
      });
      return;
    }
    showParentToast(widget.messenger, S.passwordChanged);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.changePassword,
      dirty: _dirty,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              controller: _current,
              label: S.currentPassword,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            LabeledField(
              controller: _next,
              label: S.newPassword,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            LabeledField(
              controller: _repeat,
              label: S.repeatPassword,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
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
              onPressed: _save,
              child: const Text(S.save),
            ),
          ],
        ),
      ),
    );
  }
}
