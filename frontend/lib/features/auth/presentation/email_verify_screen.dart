import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../data/auth_repository.dart';

/// Two responsibilities live here, branched by whether the URL carried a
/// `?token=…` query param:
///   - With token: auto-verify on mount and show pass/fail.
///   - Without token: show a "didn't get the email?" resend form.
class EmailVerifyScreen extends ConsumerStatefulWidget {
  final String? token;
  const EmailVerifyScreen({super.key, this.token});

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  bool _verifying = false;
  String? _error;
  bool _verified = false;

  final _resendForm = GlobalKey<FormState>();
  final _resendEmail = TextEditingController();
  bool _resending = false;
  String? _resendMessage;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _verify();
    }
  }

  @override
  void dispose() {
    _resendEmail.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmail(widget.token!);
      if (mounted) setState(() => _verified = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (!_resendForm.currentState!.validate()) return;
    setState(() {
      _resending = true;
      _resendMessage = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resendVerification(_resendEmail.text.trim());
      if (mounted) {
        setState(() => _resendMessage =
            'If that email is unverified, a new link was sent.');
      }
    } catch (e) {
      if (mounted) setState(() => _resendMessage = e.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null || widget.token!.isEmpty) {
      // Resend flow.
      return ResponsiveShell(
        title: 'Verify email',
        child: Form(
          key: _resendForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread, size: 64),
              const SizedBox(height: 12),
              Text("Didn't get the verification link?",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _resendEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => EmailValidator.validate((v ?? '').trim())
                    ? null
                    : 'Invalid email',
              ),
              if (_resendMessage != null) ...[
                const SizedBox(height: 12),
                Text(_resendMessage!),
              ],
              const SizedBox(height: 16),
              LoadingButton(
                loading: _resending,
                onPressed: _resend,
                child: const Text('Resend link'),
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

    // Token flow.
    return ResponsiveShell(
      title: 'Verify email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_verifying) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            const Text('Verifying…', textAlign: TextAlign.center),
          ] else if (_verified) ...[
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text('Email verified',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign in'),
            ),
          ] else if (_error != null) ...[
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/verify-email'),
              child: const Text('Request a new link'),
            ),
          ],
        ],
      ),
    );
  }
}
