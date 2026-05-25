import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../state/auth_controller.dart';
import '../data/auth_repository.dart' show ApiException;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isSelfDeactivated = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? raw) {  
  final v = (raw ?? '').trim();  
  if (v.isEmpty) return null; // Don't show error for empty during interaction  
  if (v.contains('@')) {  
    return EmailValidator.validate(v) ? null : 'Invalid email';  
  }  
  if (v.length < 5 || v.length > 15) return 'Phone must be 5–15 characters';  
  return null;  
}

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider)
          .login(_identifier.text.trim(), _password.text);

      // Router redirect handles navigation.
    } catch (e) {
      if (e is ApiException && e.code == 'PHONE_NOT_VERIFIED') {
        if (mounted) {
          context.go(
            '/verify-phone?phone=${Uri.encodeComponent(_identifier.text.trim())}',
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _error = e.toString();

          _isSelfDeactivated =
              (e is ApiException && e.code == 'ACCOUNT_SELF_DEACTIVATED');
        });
      }
    } finally {
      if (mounted && context.mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      title: 'Sign in',
      child: Form(
        key: _form,
         autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome back',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _identifier,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.telephoneNumber,
              ],
              decoration: const InputDecoration(
                labelText: 'Email or phone',
                hintText: 'enter email or phone you registered with',
                helperText: 'Use the email or phone you registered with',
              ),
              validator: _validateIdentifier,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) {  
  final t = (v ?? '').trim();  
  if (t.isEmpty) return null; // Don't show error for empty during interaction  
   return t.length >= 6 ? null : 'At least 6 characters';  
},
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_isSelfDeactivated) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showReactivateDialog(context),
                  child: const Text('Reactivate Account'),
                ),
              ],
            ],
            const SizedBox(height: 16),
            LoadingButton(
              loading: _loading,
              onPressed: _submit,
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Create one'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReactivateDialog(BuildContext context) {
    final identifierController = TextEditingController(text: _identifier.text);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: identifierController,
              decoration: const InputDecoration(labelText: 'Email or phone'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(authControllerProvider).reactivate(
                      identifierController.text,
                      passwordController.text,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reactivation failed: $e')),
                  );
                }
              }
            },
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }
}
