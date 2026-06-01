import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../../schools/data/school_dtos.dart';

/// Whether the user is being created with an email-as-credential or a
/// phone-as-credential. Backend supports both — same as public signup.
enum _IdentifierKind { email, phone }

class AdminUserCreateScreen extends ConsumerStatefulWidget {
  const AdminUserCreateScreen({super.key});

  @override
  ConsumerState<AdminUserCreateScreen> createState() =>
      _AdminUserCreateScreenState();
}

// Simple password field with visibility toggle
class _PasswordFieldWithToggle extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final String? Function(String?)? validator;

  const _PasswordFieldWithToggle({
    super.key,
    required this.controller,
    required this.labelText,
    this.helperText,
    this.validator,
  });

  @override
  State<_PasswordFieldWithToggle> createState() => _PasswordFieldWithToggleState();
}

class _PasswordFieldWithToggleState extends State<_PasswordFieldWithToggle> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText,
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator: widget.validator,
    );
  }
}

class _AdminUserCreateScreenState extends ConsumerState<AdminUserCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _officerRole = TextEditingController();
  UserRole _role = UserRole.moeOfficer;
  SubCity? _subCity;
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
    _confirmPassword.dispose();
    _officerRole.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    // Validate passwords match
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    // Validate MOE officer specific fields
    if (_role == UserRole.moeOfficer && _subCity == null) {
      setState(() => _error = 'Sub-city is required for MoE officers');
      return;
    }
    if (_role == UserRole.moeOfficer && _officerRole.text.trim().isEmpty) {
      setState(() => _error = 'Officer role is required for MoE officers');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Only send the credential that matches the current toggle
      final isEmail = _identifierKind == _IdentifierKind.email;
      final phoneValue = !isEmail && _phone.text.trim().isNotEmpty
          ? '+251${_phone.text.trim()}'
          : null;
      await ref.read(authControllerProvider).register(
            fullName: _name.text.trim(),
            email: isEmail ? _email.text.trim() : null,
            phone: phoneValue,
            password: _password.text,
            role: _role,
            subCity: _subCity?.toWire(),
            officerRole: _role == UserRole.moeOfficer ? _officerRole.text.trim() : null,
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
      return ResponsiveShell(
        title: 'Account created',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/moderation'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Account created successfully',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/moderation'),
              child: const Text('Back to moderation'),
            ),
          ],
        ),
      );
    }

    return ResponsiveShell(
      title: 'Create MoE officer/ moderator',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/moderation'),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v ?? '').trim().isNotEmpty ? null : 'Required',
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
              onSelectionChanged: (Set<_IdentifierKind> s) {
                if (s.isNotEmpty) {
                  setState(() => _identifierKind = s.first);
                }
              },
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
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Required';
                  // Basic email validation
                  if (!t.contains('@') || !t.contains('.')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              )
            else
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixText: '+251',
                  helperText: 'Enter 9 or 7 followed by 8 digits',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Required';
                  if (t.length != 9) {
                    return 'Enter 9 digits after +251';
                  }
                  if (!t.startsWith('9') && !t.startsWith('7')) {
                    return 'Must start with 9 or 7';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 12),
            _PasswordFieldWithToggle(
              controller: _password,
              labelText: 'Password',
              helperText: 'Minimum 6 characters',
              validator: (v) =>
                  (v ?? '').length >= 6 ? null : 'At least 6 characters',
            ),
            const SizedBox(height: 12),
            _PasswordFieldWithToggle(
              controller: _confirmPassword,
              labelText: 'Confirm Password',
              helperText: 'Re-enter password to confirm',
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Required';
                if (v != _password.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(
                    value: UserRole.moeOfficer,
                    child: Text('MoE Officer')),
                DropdownMenuItem(
                    value: UserRole.moderator,
                    child: Text('Moderator')),
              ],
              onChanged: (v) => setState(() => _role = v ?? UserRole.moeOfficer),
            ),
            const SizedBox(height: 12),
            // Show subcity dropdown only for MOE officers
            if (_role == UserRole.moeOfficer) ...[
              DropdownButtonFormField<SubCity>(
                decoration: const InputDecoration(labelText: 'Sub-city *'),
                value: _subCity,
                items: SubCity.values.map((subCity) {
                  return DropdownMenuItem(value: subCity, child: Text(subCity.label));
                }).toList(),
                onChanged: (v) => setState(() => _subCity = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _officerRole,
                decoration: const InputDecoration(
                  labelText: 'Officer Role *',
                  helperText: 'e.g., Senior Inspector, Regional Officer',
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
            ],
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
          ],
        ),
      ),
    );
  }
}