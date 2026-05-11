import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  // Backend always responds 200 (per spec — don't leak which emails exist), so
  // the success message is intentionally generic.
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(_email.text.trim());
      if (mounted) {
        setState(() => _message =
            'If that email belongs to an active account, a reset link was sent.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      title: 'Forgot password',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Enter your email and we'll send you a reset link.",
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => EmailValidator.validate((v ?? '').trim())
                  ? null
                  : 'Invalid email',
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!),
            ],
            const SizedBox(height: 16),
            LoadingButton(
              loading: _loading,
              onPressed: _submit,
              child: const Text('Send reset link'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
