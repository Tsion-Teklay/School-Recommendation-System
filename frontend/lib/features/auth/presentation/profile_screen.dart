import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/message_helper.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/password_field.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../schools/data/school_dtos.dart';
import '../../schools/data/school_repository.dart';
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
  int? _schoolCount;

  void _seedFromUser(AppUser user) {
    if (_initialized) return;
    _name.text = user.fullName;
    _phone.text = user.phone ?? '';
    _initialized = true;
    
    // Load school count if user is a school admin
    if (user.role == UserRole.schoolAdmin) {
      _loadSchoolCount();
    }
  }

  Future<void> _loadSchoolCount() async {
    try {
      // Use the existing list endpoint with limit=1 to get count
      final userId = ref.read(authControllerProvider).user?.id;
      if (userId == null) {
        setState(() => _schoolCount = 0);
        return;
      }
      
      final result = await ref.read(schoolRepositoryProvider).list(
        SchoolListFilters(
          adminId: userId,
          page: 1,
          limit: 1,
        ),
      );
      if (mounted) {
        setState(() => _schoolCount = result.meta.total);
      }
    } catch (e) {
      // Silently fail - school count is optional info
      if (mounted) {
        setState(() => _schoolCount = 0);
      }
    }
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
      // Backend Zod treats phone as optional `min(5).max(15)` — an empty
      // string fails validation. Convert empty to null so the field is dropped
      // from the request body, matching the register-screen behavior.
      final trimmedPhone = _phone.text.trim();
      await ref.read(authControllerProvider).updateProfile(
            fullName: _name.text.trim(),
            phone: trimmedPhone.isEmpty ? null : trimmedPhone,
          );
      if (mounted) {
        setState(() => _saveMessage = 'Profile updated.');
        MessageHelper.showSuccess(context, SuccessMessages.profileUpdated);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saveMessage = ErrorHandler.getUserFriendlyMessage(e));
        MessageHelper.showError(context, ErrorHandler.getUserFriendlyMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<({String current, String next, String confirm})>(
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
      MessageHelper.showSuccess(context, SuccessMessages.passwordChanged);
    } catch (e) {
      if (!mounted) return;
      MessageHelper.showError(context, ErrorHandler.getUserFriendlyMessage(e));
    }
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await MessageHelper.showConfirmationDialog(
      context,
      'Deactivate account?',
      'Your account will be marked DEACTIVATED and you will be signed out. '
      'You can reactivate it later by logging in with your credentials.',
      confirmText: 'Deactivate',
    );
    if (confirmed != true) return;
    try {
      await ref.read(authControllerProvider).deactivate();
      if (mounted) MessageHelper.showSuccess(context, SuccessMessages.accountDeactivated);
      // On success the auth-state change → router redirects to /login.
    } catch (e) {
      if (!mounted) return;
      MessageHelper.showError(context, ErrorHandler.getUserFriendlyMessage(e));
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider).logout();
  }

  Future<void> _deleteAllSchools() async {
    final confirmed = await MessageHelper.showConfirmationDialog(
      context,
      'Delete All Schools',
      'This will permanently delete all your schools. This action cannot be undone.',
      confirmText: 'Delete All',
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      // Get all schools first
      final userId = ref.read(authControllerProvider).user?.id;
      if (userId == null) return;
      
      final allSchools = await ref.read(schoolRepositoryProvider).list(
        SchoolListFilters(adminId: userId, page: 1, limit: 100),
      );
      
      // Extract school IDs first to avoid reference issues
      final schoolIds = allSchools.items.map((school) => school.id).toList();
      
      // Delete each school individually by ID
      for (var schoolId in schoolIds) {
        await ref.read(schoolRepositoryProvider).delete(schoolId);
      }
      
      if (mounted) {
        MessageHelper.showSuccess(context, 'All ${schoolIds.length} school(s) deleted successfully');
        setState(() => _schoolCount = 0);
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, ErrorHandler.getUserFriendlyMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

Future<void> _handleSchoolAdminAccountDeletion() async {
  // Load current school count
  if (_schoolCount == null) {
    await _loadSchoolCount();
  }

  // If admin has schools, show error message with option to delete them
  if (_schoolCount != null && _schoolCount! > 0) {
    MessageHelper.showError(
      context,
      'You have $_schoolCount school(s). Please delete all your schools before you can delete your account.',
    );
    
    // Ask if they want to delete all schools now
    final deleteSchools = await MessageHelper.showConfirmationDialog(
      context,
      'Delete Schools',
      'Would you like to delete all your schools now?',
      confirmText: 'Delete All Schools',
      cancelText: 'Cancel',
    );
    
    if (deleteSchools == true) {
      await _deleteAllSchools();
    }
    return;
  }

  // If no schools, proceed with normal deletion flow
  await _handleRegularAccountDeletion();
}

Future<void> _handleRegularAccountDeletion() async {
  final confirmed = await MessageHelper.showConfirmationDialog(
    context,
    'Delete Account Permanently',
    'This action cannot be undone. All your data will be permanently deleted.',
    confirmText: 'Delete',
    isDestructive: true,
  );

  if (confirmed != true) return;

  final passwordController = TextEditingController();

  final passwordConfirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Password'),
      content: PasswordField(
        controller: passwordController,
        hintText: 'Enter your password',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (passwordConfirmed == true && passwordController.text.isNotEmpty) {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .deletePermanently(passwordController.text);

      if (mounted) {
        MessageHelper.showSuccess(context, 'Account deleted permanently');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, ErrorHandler.getUserFriendlyMessage(e));
      }
    }
  }
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
         autovalidateMode: AutovalidateMode.onUserInteraction,
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
            if (user.role == UserRole.parent)
              OutlinedButton.icon(
                onPressed: () => context.go('/preferences'),
                icon: const Icon(Icons.tune),
                label: const Text('Recommendation preferences'),
              ),
            if (user.role == UserRole.parent)  
              OutlinedButton.icon(  
                onPressed: () => context.go('/followed-schools'),  
                icon: const Icon(Icons.school),  
                label: const Text('Manage followed schools'),  
              ),  
            if (user.role == UserRole.parent) const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                // For school admins, check if they have schools first
                if (user.role == UserRole.schoolAdmin) {
                  await _handleSchoolAdminAccountDeletion();
                } else {
                  await _handleRegularAccountDeletion();
                }
              },
              icon: const Icon(Icons.warning),
              label: const Text('Delete Account Permanently'),
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
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
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
            PasswordField(
              controller: _current,
              labelText: 'Current password',
              validator: (v) =>
                  (v ?? '').isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _next,
              labelText: 'New password',
              helperText: 'Min 6 chars, must differ',
              validator: (v) {
                if ((v ?? '').length < 6) return 'At least 6 characters';
                if (v == _current.text) return 'Must differ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _confirm,
              labelText: 'Confirm new password',
              validator: (v) {
                if (v != _next.text) return 'Passwords do not match';
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
              (current: _current.text, next: _next.text, confirm: _confirm.text),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
