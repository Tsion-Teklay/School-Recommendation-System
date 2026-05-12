import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
  
import '../../../shared/widgets/loading_button.dart';  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../auth/data/auth_dtos.dart';  
import '../../auth/state/auth_controller.dart';  
  
class AdminUserCreateScreen extends ConsumerStatefulWidget {  
  const AdminUserCreateScreen({super.key});  
  
  @override  
  ConsumerState<AdminUserCreateScreen> createState() =>  
      _AdminUserCreateScreenState();  
}  
  
class _AdminUserCreateScreenState extends ConsumerState<AdminUserCreateScreen> {  
  final _form = GlobalKey<FormState>();  
  final _name = TextEditingController();  
  final _email = TextEditingController();  
  final _phone = TextEditingController();  
  final _password = TextEditingController();  
  UserRole _role = UserRole.moeOfficer;  
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
      await ref.read(authControllerProvider).register(  
            fullName: _name.text.trim(),  
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),  
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),  
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
      title: 'Create admin user',  
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
            TextFormField(  
              controller: _email,  
              keyboardType: TextInputType.emailAddress,  
              decoration: const InputDecoration(  
                labelText: 'Email (optional)',  
                helperText: 'Leave empty for phone-only signup',  
              ),  
            ),  
            const SizedBox(height: 12),  
            TextFormField(  
              controller: _phone,  
              keyboardType: TextInputType.phone,  
              decoration: const InputDecoration(  
                labelText: 'Phone (optional)',  
                helperText: '5–15 characters',  
              ),  
              validator: (v) {  
                final t = (v ?? '').trim();  
                if (t.isEmpty && _email.text.trim().isEmpty) {  
                  return 'Either email or phone is required';  
                }  
                if (t.isNotEmpty && (t.length < 5 || t.length > 15)) {  
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