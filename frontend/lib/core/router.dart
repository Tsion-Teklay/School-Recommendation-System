import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_announcements_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/admin_school_manage_screen.dart';
import '../features/auth/presentation/email_verify_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/comparisons/presentation/comparison_detail_screen.dart';
import '../features/comparisons/presentation/comparisons_list_screen.dart';
import '../features/comparisons/presentation/new_comparison_screen.dart';
import '../features/forum/presentation/forum_detail_screen.dart';
import '../features/forum/presentation/forum_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/moderation/presentation/moderation_reports_screen.dart';
import '../features/moe/presentation/moe_announcements_screen.dart';
import '../features/moe/presentation/moe_dashboard_screen.dart';
import '../features/moe/presentation/moe_home_screen.dart';
import '../features/moe/presentation/moe_verification_queue_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/schools/presentation/school_detail_screen.dart';
import '../features/schools/presentation/schools_list_screen.dart';

/// Lists routes that anyone (logged in or not) is allowed to hit. Email-verify
/// + reset-password are public because they're entered from email deep links;
/// hiding them behind auth would be a chicken-and-egg loop.
const _publicRoutes = <String>{
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/verify-email',
};

final routerProvider = Provider<GoRouter>((ref) {
  // We deliberately `read` rather than `watch` here. The router itself only
  // needs the AuthController instance once (to wire `refreshListenable`); the
  // `redirect` callback below closes over `auth` and re-runs on every nav
  // event, so it always sees the latest auth state.
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.initializing) return null;

      final goingPublic = _publicRoutes.any(
        (p) => state.matchedLocation.startsWith(p),
      );

      if (!auth.isAuthenticated && !goingPublic) {
        return '/login';
      }
      if (auth.isAuthenticated && goingPublic) {
        if (state.matchedLocation.startsWith('/verify-email') ||
            state.matchedLocation.startsWith('/reset-password')) {
          return null;
        }
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => EmailVerifyScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/schools',
        builder: (_, __) => const SchoolsListScreen(),
      ),
      GoRoute(
        path: '/schools/:id',
        builder: (_, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return Scaffold(
              body: Center(child: Text('Invalid school id: $raw')),
            );
          }
          return SchoolDetailScreen(schoolId: id);
        },
      ),
      GoRoute(
        path: '/compare',
        builder: (_, __) => const ComparisonsListScreen(),
      ),
      GoRoute(
        path: '/compare/new',
        builder: (_, __) => const NewComparisonScreen(),
      ),
      GoRoute(
        path: '/compare/:id',
        builder: (_, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return Scaffold(
              body: Center(child: Text('Invalid comparison id: $raw')),
            );
          }
          return ComparisonDetailScreen(comparisonId: id);
        },
      ),
      // Phase 9: notifications inbox.
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      // Phase 9: forum.
      GoRoute(
        path: '/forum',
        builder: (_, __) => const ForumListScreen(),
      ),
      GoRoute(
        path: '/forum/:id',
        builder: (_, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return Scaffold(
              body: Center(child: Text('Invalid post id: $raw')),
            );
          }
          return ForumDetailScreen(postId: id);
        },
      ),
      // Phase 9: school-admin portal.
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/announcements',
        builder: (_, __) => const AdminAnnouncementsScreen(),
      ),
      GoRoute(
        path: '/admin/schools/:id',
        builder: (_, state) {
          final raw = state.pathParameters['id'];
          final id = int.tryParse(raw ?? '');
          if (id == null) {
            return Scaffold(
              body: Center(child: Text('Invalid school id: $raw')),
            );
          }
          return AdminSchoolManageScreen(schoolId: id);
        },
      ),
      // Phase 9: MoE portal.
      GoRoute(path: '/moe', builder: (_, __) => const MoeHomeScreen()),
      GoRoute(
        path: '/moe/dashboard',
        builder: (_, __) => const MoeDashboardScreen(),
      ),
      GoRoute(
        path: '/moe/verifications',
        builder: (_, __) => const MoeVerificationQueueScreen(),
      ),
      GoRoute(
        path: '/moe/announcements',
        builder: (_, __) => const MoeAnnouncementsScreen(),
      ),
      // Phase 9: moderation portal.
      GoRoute(
        path: '/moderation',
        builder: (_, __) => const ModerationReportsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
