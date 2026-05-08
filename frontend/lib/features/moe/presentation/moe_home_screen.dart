import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/state/auth_controller.dart';

class MoeHomeScreen extends ConsumerWidget {
  const MoeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    return ResponsiveShell(
      title: 'Ministry of Education',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome${user != null ? ', ${user.fullName}' : ''}!',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Review pending school verifications, monitor system-wide '
            'analytics, and publish ministry announcements that fan out to '
            'every parent.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (ctx, c) {
              final wide = c.maxWidth > 700;
              final cards = [
                _ActionCard(
                  icon: Icons.dashboard_outlined,
                  title: 'Analytics dashboard',
                  body:
                      'System-wide counts, top schools, most followed, CSV export.',
                  buttonLabel: 'Open dashboard',
                  onTap: () => context.go('/moe/dashboard'),
                ),
                _ActionCard(
                  icon: Icons.verified_outlined,
                  title: 'Verification queue',
                  body:
                      'Approve or reject pending school verification requests.',
                  buttonLabel: 'Open queue',
                  onTap: () => context.go('/moe/verifications'),
                ),
                _ActionCard(
                  icon: Icons.campaign_outlined,
                  title: 'Ministry announcements',
                  body:
                      'Publish announcements that fan out to every parent.',
                  buttonLabel: 'Manage announcements',
                  onTap: () => context.go('/moe/announcements'),
                ),
              ];
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ]
                  ],
                );
              }
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 12),
                  ]
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 12),
            FilledButton(onPressed: onTap, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
