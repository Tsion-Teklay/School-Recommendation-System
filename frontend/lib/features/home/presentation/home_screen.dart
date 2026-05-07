import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../../recommendations/presentation/recommendations_screen.dart';

/// Role-routed home.
///
/// - **Parents** see the recommendations dashboard (Phase 8 headline feature).
/// - **Other roles** see a placeholder card pointing at the browse list. Their
///   bespoke dashboards land in Phase 9 (school admin portal, MoE analytics,
///   moderator review queue) — surfacing a stub here keeps the nav consistent
///   without pretending to do work we haven't shipped yet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user?.role == UserRole.parent) {
      return const RecommendationsScreen();
    }
    return const _RoleStubHome();
  }
}

class _RoleStubHome extends ConsumerWidget {
  const _RoleStubHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);
    return ResponsiveShell(
      title: 'School Recommendation System',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome${user != null ? ', ${user.fullName}' : ''}!',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          if (user != null)
            Text(
              'Signed in as ${user.email} · ${user.role.label()}',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phase 8 — schools, comparisons, maps',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'You can browse the school catalog, view detailed school '
                    'pages with embedded maps, and (as a parent) build saved '
                    'side-by-side comparisons.\n\n'
                    'Role-specific dashboards (school admin portal, MoE '
                    'analytics, moderation queue) land in Phase 9.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/schools'),
                    icon: const Icon(Icons.search),
                    label: const Text('Browse schools'),
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
