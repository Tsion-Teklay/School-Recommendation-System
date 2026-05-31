import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../features/auth/data/auth_dtos.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/notifications/state/notifications_controller.dart';
import 'custom_navigation.dart';

/// Breakpoints we use everywhere. Mirrors Material 3 window-size classes.
class Breakpoints {
  static const double compact = 600;
  static const double medium = 1200;
}

/// One destination in the global app nav. The shell shows a role-filtered
/// subset on each viewport size.
class NavDestination {
  final String label;
  final IconData icon;
  final String path;

  /// If non-null, only users with one of these roles see this destination.
  /// Null means "everyone (including unauthenticated)".
  final Set<UserRole>? visibleTo;
  const NavDestination({
    required this.label,
    required this.icon,
    required this.path,
    this.visibleTo,
  });
}

const _allDestinations = <NavDestination>[
  NavDestination(label: 'Home', icon: Icons.home_outlined, path: '/'),
  NavDestination(
      label: 'Browse', icon: Icons.search_outlined, path: '/schools'),
  NavDestination(  
    label: 'Announcements',  
    icon: Icons.campaign_outlined,  
    path: '/announcements',  
    visibleTo: {UserRole.parent}, // Restrict to parents as requested  
  ),  
  NavDestination(
    label: 'Compare',
    icon: Icons.compare_arrows_outlined,
    path: '/compare',
    visibleTo: {UserRole.parent},
  ),
  NavDestination(
    label: 'Forum',
    icon: Icons.forum_outlined,
    path: '/forum',
  ),
  NavDestination(
    label: 'Inbox',
    icon: Icons.notifications_outlined,
    path: '/notifications',
  ),
  NavDestination(
    label: 'Reports',
    icon: Icons.report_gmailerrorred,
    path: '/moderation',
    visibleTo: {UserRole.moderator},
  ),
];

/// Wraps a screen body in a Scaffold whose chrome adapts to the viewport:
///   < 600px wide  → AppBar + body + BottomNavigationBar (mobile portrait).
///   600–1200px    → AppBar + NavigationRail (icon-only) + body (tablet).
///   > 1200px      → AppBar + extended NavigationRail + body (desktop).
///
/// When the user isn't authenticated (or [showNav] is false) we skip the nav
/// chrome entirely so the auth screens stay clean.
class ResponsiveShell extends ConsumerWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final bool showNav;

  /// Optional callback for scroll notifications bubbling up from the body.
  /// The body is wrapped in a `SingleChildScrollView`, so descendants can't
  /// own the scroll directly — exposing this lets paginated screens trigger
  /// "load more" when the outer scroll approaches its max extent.
  final bool Function(ScrollNotification)? onScrollNotification;

  const ResponsiveShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.showNav = true,
    this.onScrollNotification,
  });

  List<NavDestination> _visibleDestinations(UserRole? role) {
    return _allDestinations.where((d) {
      if (d.visibleTo == null) return true;
      if (role == null) return false;
      return d.visibleTo!.contains(role);
    }).toList();
  }

  int _selectedIndex(String location, List<NavDestination> dests) {
    // Match the longest path prefix so /schools/42 still highlights "Browse".
    var best = -1;
    var bestLen = -1;
    for (var i = 0; i < dests.length; i++) {
      final p = dests[i].path;
      final isMatch = p == '/'
          ? location == '/'
          : location == p || location.startsWith('$p/');
      if (isMatch && p.length > bestLen) {
        best = i;
        bestLen = p.length;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.user?.role;
    final dests = showNav && auth.isAuthenticated
        ? _visibleDestinations(role)
        : const <NavDestination>[];
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(location, dests);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMedium = constraints.maxWidth >= Breakpoints.compact &&
            constraints.maxWidth < Breakpoints.medium;
        final isExpanded = constraints.maxWidth >= Breakpoints.medium;
        final isCompact = constraints.maxWidth < Breakpoints.compact;

        final defaultActions = <Widget>[
          // No actions in navbar - profile and notifications are floating buttons
        ];

        final scrollable = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isExpanded
                    ? 1100.0
                    : (isMedium ? constraints.maxWidth - 48 : double.infinity),
              ),
              child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
        ],
      ),  
            ),
          ),
        );
        final body = onScrollNotification != null
            ? NotificationListener<ScrollNotification>(
                onNotification: onScrollNotification,
                child: scrollable,
              )
            : scrollable;

        // Bottom-nav can only safely show ~5 items; if we have more (e.g.
        // an admin with Home/Browse/Forum/Inbox/Admin) we drop overflow
        // items off the bar but keep them reachable from the rail / direct
        // links / drawer (drawer is a follow-up if needed).
        final bottomDests = dests.length > 5 ? dests.sublist(0, 5) : dests;
        final bottomSelected =
            _selectedIndex(location, bottomDests).clamp(-1, bottomDests.length - 1);

        return Scaffold(
          appBar: AppNavigationBar(
            title: title,
            actions: [...?actions, ...defaultActions],
            leading: leading,
          ),
          floatingActionButton: floatingActionButton,
          body: Stack(
            children: [
              dests.isEmpty || isCompact
                  ? body
                  : Row(
                      children: [
                        AppNavigationRail(
                          selectedIndex: selected >= 0 ? selected : 0,
                          items: dests
                              .map((d) => NavigationItem(
                                    label: d.label,
                                    icon: d.icon,
                                  ))
                              .toList(),
                          onDestinationSelected: (i) => context.go(dests[i].path),
                          extended: isExpanded,
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    ),
              // Floating notification button
              if (auth.isAuthenticated)
                FloatingNotificationButton(
                  unreadCount: ref.watch(notificationsControllerProvider).unreadTotal,
                  onTap: () => context.go('/notifications'),
                ),
              // Floating profile button (consistent - at very top corner)
              // Only show when not on profile page
              if (auth.isAuthenticated && !location.startsWith('/profile'))
                FloatingProfileButton(
                  onTap: () => context.go('/profile'),
                ),
            ],
          ),
          bottomNavigationBar: bottomDests.isNotEmpty && isCompact
              ? AppBottomNavigation(
                  selectedIndex: bottomSelected >= 0 ? bottomSelected : 0,
                  items: bottomDests
                      .map((d) => NavigationItem(
                            label: d.label,
                            icon: d.icon,
                          ))
                      .toList(),
                  onDestinationSelected: (i) => context.go(bottomDests[i].path),
                )
              : null,
        );
      },
    );
  }
}