import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/state/auth_controller.dart';
import '../../auth/data/auth_dtos.dart';
import '../data/notification_dtos.dart';
import '../state/notifications_controller.dart';

/// Inbox view of `/api/notifications`. Two-tab toggle (All / Unread) +
/// tap-to-mark-read. Pagination follows the same NotificationListener
/// pattern Phase 8 introduced for the schools list.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider).ensureLoaded();
    });
  }

  bool _onScroll(ScrollNotification n) {
    final controller = ref.read(notificationsControllerProvider);
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      controller.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(notificationsControllerProvider);
    return ResponsiveShell(
      title: 'Notifications',
      onScrollNotification: _onScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('All')),
                    ButtonSegment(value: true, label: Text('Unread')),
                  ],
                  selected: {controller.unreadOnly},
                  onSelectionChanged: (s) => controller.setUnreadOnly(s.first),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.loading ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  controller.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          if (controller.loading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No notifications.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = controller.items[i];
                return _NotificationTile(
                  n: n,
                  onTap: () => _handleTap(n),
                );
              },
            ),
          if (controller.appending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!controller.loading &&
              !controller.appending &&
              controller.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: controller.loadMore,
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(AppNotification n) {
    final controller = ref.read(notificationsControllerProvider);
    if (!n.isRead) {
      controller.markRead(n.id);
    }
    final user = ref.read(authControllerProvider).user;
    final dest = _routeFor(n, user?.role);
    if (dest != null) {
      context.push(dest);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      // Highlight unread with a subtle tint so the eye lands there first.
      color: n.isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          foregroundColor: theme.colorScheme.primary,
          child: Icon(_iconFor(n.sourceType)),
        ),
        title: Text(n.message),
        subtitle: Text(
          '${n.sourceType.label()} · ${_formatDate(n.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: n.isRead
            ? null
            : Icon(Icons.fiber_manual_record,
                color: theme.colorScheme.primary, size: 12),
        onTap: onTap,
      ),
    );
  }
}

IconData _iconFor(NotificationSourceType t) {
  switch (t) {
    case NotificationSourceType.announcement:
      return Icons.campaign_outlined;
    case NotificationSourceType.report:
      return Icons.flag_outlined;
    case NotificationSourceType.review:
      return Icons.rate_review_outlined;
    case NotificationSourceType.school:
      return Icons.school_outlined;
    case NotificationSourceType.forumPost:
      return Icons.forum_outlined;
    case NotificationSourceType.moderation:
      return Icons.gavel_outlined;
    case NotificationSourceType.system:
      return Icons.info_outline;
  }
}

/// Map a notification to its in-app destination. We pick conservative routes
/// here — anything we can't resolve (e.g. report notifications for parents,
/// who can't see the moderation queue) just no-ops back to the inbox.
String? _routeFor(AppNotification n, UserRole? role) {
  final id = n.sourceId;
  if (id == null) return null;
  switch (n.sourceType) {
    case NotificationSourceType.school:
      return '/schools/$id';
    case NotificationSourceType.forumPost:
      return '/forum/$id';
    case NotificationSourceType.announcement:
      // Phase 11 — deep-link parents into the announcement detail screen.
      return '/announcements/$id';
    case NotificationSourceType.report:
      if (role == UserRole.moderator) {
        return '/moderation';
      }
      return null;
    case NotificationSourceType.review:
    case NotificationSourceType.moderation:
    case NotificationSourceType.system:
      return null;
  }
}

String _formatDate(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
