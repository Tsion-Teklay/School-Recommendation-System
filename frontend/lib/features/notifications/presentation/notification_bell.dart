import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/notifications_controller.dart';

/// AppBar bell + unread-count badge. Reads the controller's cached
/// `unreadTotal` and tap-routes to `/notifications`.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider).refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(notificationsControllerProvider);
    final count = controller.unreadTotal;
    return IconButton(
      tooltip: count > 0 ? '$count unread notification(s)' : 'Notifications',
      onPressed: () => context.go('/notifications'),
      icon: count > 0
          ? Badge(
              label: Text(count > 99 ? '99+' : '$count'),
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
    );
  }
}
