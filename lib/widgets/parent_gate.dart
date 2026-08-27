import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';

Future<bool> askParent(BuildContext context, {String? message}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ParentGateDialog(message: message ?? S.parentPrompt),
  );
  return ok == true;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.message});

  final String message;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _controller = TextEditingController();
  var _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = HabitScope.of(context).checkPassword(_controller.text);
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() => _error = true);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(S.parentTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error) setState(() => _error = false);
            },
            decoration: InputDecoration(
              hintText: S.passwordHint,
              errorText: _error ? S.wrongPassword : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(S.cancel),
        ),
        FilledButton(onPressed: _submit, child: const Text(S.verify)),
      ],
    );
  }
}

Future<void> showParentTaskActions(
  BuildContext context, {
  required VoidCallback onAward,
  required VoidCallback onSendBack,
}) async {
  final allowed = await askParent(context);
  if (!allowed || !context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(S.parentTitle),
        content: const Text('Завдання виконано добре?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onSendBack();
            },
            child: const Text(
              S.sendBack,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onAward();
            },
            child: const Text(S.awardPoints),
          ),
        ],
      );
    },
  );
}
