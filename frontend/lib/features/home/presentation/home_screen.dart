import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';

/// Placeholder home — will be replaced in Phase 8 with the school browse list
/// and in Phase 9 with role-specific dashboards. For now it just confirms the
/// user is signed in and links to /profile so we can demo the auth round trip.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return ResponsiveShell(
      title: 'School Recommendation System',
      actions: [
        IconButton(
          tooltip: 'Profile',
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.person),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome${user != null ? ', ${user.fullName}' : ''}!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (user != null)
            Text(
              'Signed in as ${user.email} · ${user.role.label()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phase 7 — auth scaffolding',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'You can register, verify your email, sign in, recover '
                    'your password, edit your profile, change your password, '
                    'and deactivate your account.\n\n'
                    'Phase 8 will plug school browse + detail + comparison + '
                    'maps in here.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
