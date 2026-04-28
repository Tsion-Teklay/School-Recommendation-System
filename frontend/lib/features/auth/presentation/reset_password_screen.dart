import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../data/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;
  const ResetPasswordScreen({super.key, this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: widget.token!,
            newPassword: _password.text,
          );
      if (mounted) setState(() => _done = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null || widget.token!.isEmpty) {
      return ResponsiveShell(
        title: 'Reset password',
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 12),
            const Text(
              'This page expects a reset token from the email link.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text('Request a new link'),
            ),
          ],
        ),
      );
    }
    if (_done) {
      return ResponsiveShell(
        title: 'Reset password',
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text('Password updated',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign in with the new password'),
            ),
          ],
        ),
      );
    }

    return ResponsiveShell(
      title: 'Reset password',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'Minimum 6 characters',
              ),
              validator: (v) =>
                  (v ?? '').length >= 6 ? null : 'At least 6 characters',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (v) =>
                  v == _password.text ? null : 'Passwords do not match',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            LoadingButton(
              loading: _loading,
              onPressed: _submit,
              child: const Text('Update password'),
            ),
          ],
        ),
      ),
    );
  }
}
