import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../data/auth_dtos.dart';
import '../data/auth_repository.dart';
import '../state/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  String? _saveMessage;
  bool _initialized = false;

  void _seedFromUser(AppUser user) {
    if (_initialized) return;
    _name.text = user.fullName;
    _phone.text = user.phone ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    try {
      await ref.read(authControllerProvider).updateProfile(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
          );
      setState(() => _saveMessage = 'Profile updated.');
    } catch (e) {
      setState(() => _saveMessage = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: result.current,
            newPassword: result.next,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate account?'),
        content: const Text(
          'Your account will be marked DEACTIVATED and you will be signed out. '
          'Future logins will fail until an admin reactivates the account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider).deactivate();
    // Auth-state change → router redirects to /login.
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const ResponsiveShell(
        title: 'Profile',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    _seedFromUser(user);

    return ResponsiveShell(
      title: 'Profile',
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.fullName,
                  style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text(
                  '${user.email} · ${user.role.label()}'
                  '${user.emailVerified ? '' : ' · Email NOT verified'}'),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v ?? '').trim().isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                helperText: '5–15 characters, or empty',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                if (t.length < 5 || t.length > 15) return '5–15 characters';
                return null;
              },
            ),
            if (_saveMessage != null) ...[
              const SizedBox(height: 12),
              Text(_saveMessage!),
            ],
            const SizedBox(height: 16),
            LoadingButton(
              loading: _saving,
              onPressed: _save,
              child: const Text('Save changes'),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change password'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: _confirmDeactivate,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Deactivate account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (v) =>
                  (v ?? '').isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'Min 6 chars, must differ',
              ),
              validator: (v) {
                if ((v ?? '').length < 6) return 'At least 6 characters';
                if (v == _current.text) return 'Must differ';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              (current: _current.text, next: _next.text),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
