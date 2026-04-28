import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/email_verify_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/home/presentation/home_screen.dart';

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
  //
  // Using `watch` would cause Riverpod to invalidate `routerProvider` on every
  // `notifyListeners()` call (login, profile update, etc.), rebuilding the
  // GoRouter from scratch with `initialLocation: '/'` and resetting the user's
  // navigation stack — which on mobile manifests as getting bounced back to
  // the home page after every save action.
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      // While we're checking the stored JWT we keep the current location so
      // the user doesn't see a flash of /login before bouncing back to /.
      if (auth.initializing) return null;

      final goingPublic = _publicRoutes.any(
        (p) => state.matchedLocation.startsWith(p),
      );

      if (!auth.isAuthenticated && !goingPublic) {
        return '/login';
      }
      if (auth.isAuthenticated && goingPublic) {
        // Don't bounce people *out* of /verify-email or /reset-password if
        // they happen to be logged in already — those flows still need to
        // run to completion.
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
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
