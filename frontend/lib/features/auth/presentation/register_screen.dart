import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../data/auth_dtos.dart';
import '../state/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

/// Whether the user is signing up with an email-as-credential (legacy path,
/// gated by a verification email) or a phone-as-credential (no verification,
/// usable immediately). Backend supports both — see Phase 10 backend changes.
enum _IdentifierKind { email, phone }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  // MoE / Moderator accounts are admin-created per the spec, so the public
  // self-registration form only exposes the two consumer roles.
  UserRole _role = UserRole.parent;
  _IdentifierKind _identifierKind = _IdentifierKind.email;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Only send the credential that matches the current toggle. The "other"
      // field is hidden from the form, so sending it would be lying to the
      // backend's uniqueness checks.
      final isEmail = _identifierKind == _IdentifierKind.email;
      await ref.read(authControllerProvider).register(
            fullName: _name.text.trim(),
            email: isEmail ? _email.text.trim() : null,
            phone: !isEmail ? _phone.text.trim() : null,
            password: _password.text,
            role: _role,
          );
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      final isEmail = _identifierKind == _IdentifierKind.email;
      // Two different success states: email-path users have something to do
      // (open the verification link), phone-path users can sign in directly.
      return ResponsiveShell(
        title: isEmail ? 'Check your email' : 'Account created',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              isEmail ? Icons.mark_email_read : Icons.check_circle_outline,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isEmail
                  ? "We sent a verification link to ${_email.text.trim()}."
                  : "You can now sign in with phone ${_phone.text.trim()}.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isEmail
                  ? "Click the link to activate your account, then come back here to sign in."
                  : "Use your phone number and password to sign in.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      );
    }

    return ResponsiveShell(
      title: 'Create account',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v ?? '').trim().isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 12),
            SegmentedButton<_IdentifierKind>(
              segments: const [
                ButtonSegment(
                  value: _IdentifierKind.email,
                  label: Text('Email'),
                  icon: Icon(Icons.mail_outline),
                ),
                ButtonSegment(
                  value: _IdentifierKind.phone,
                  label: Text('Phone'),
                  icon: Icon(Icons.phone_outlined),
                ),
              ],
              selected: {_identifierKind},
              onSelectionChanged: (s) =>
                  setState(() => _identifierKind = s.first),
            ),
            const SizedBox(height: 12),
            if (_identifierKind == _IdentifierKind.email)
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@gmail.com',
                  helperText: "We'll send a verification link to this address.",
                ),
                validator: (v) => EmailValidator.validate((v ?? '').trim())
                    ? null
                    : 'Invalid email',
              )
            else
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  helperText:
                      '5–15 characters. No verification step — usable right away.',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.length < 5 || t.length > 15) {
                    return '5–15 characters';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: 'Minimum 6 characters',
              ),
              validator: (v) =>
                  (v ?? '').length >= 6 ? null : 'At least 6 characters',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'I am a…'),
              items: const [
                DropdownMenuItem(value: UserRole.parent, child: Text('Parent')),
                DropdownMenuItem(
                    value: UserRole.schoolAdmin,
                    child: Text('School administrator')),
              ],
              onChanged: (v) => setState(() => _role = v ?? UserRole.parent),
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
              child: const Text('Create account'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
