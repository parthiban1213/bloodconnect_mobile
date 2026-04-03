import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/feed/feed_screen.dart';
import '../views/detail/requirement_detail_screen.dart';
import '../views/detail/accepted_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/directory/directory_screen.dart';
import '../views/donors/donors_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/my_requests/my_requests_screen.dart';
import '../views/my_requests/add_requirement_screen.dart';
import '../views/history/history_screen.dart';
import '../views/shell/main_shell.dart';
import '../views/support/support_screen.dart'; // ← NEW

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (previous?.isLoggedIn    != next.isLoggedIn ||
          previous?.isCheckingAuth != next.isCheckingAuth) {
        notifyListeners();
      }
    });
  }
  final Ref _ref;
  bool get isLoggedIn      => _ref.read(authViewModelProvider).isLoggedIn;
  bool get isCheckingAuth  => _ref.read(authViewModelProvider).isCheckingAuth;
}

final _authRouterNotifierProvider =
    ChangeNotifierProvider<_AuthRouterNotifier>((ref) {
  return _AuthRouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      // During startup _checkAuth, stay on /login (white guard in LoginScreen)
      if (notifier.isCheckingAuth) {
        return state.matchedLocation == '/login' ? null : '/login';
      }
      final isLoggedIn = notifier.isLoggedIn;
      final onAuthPage = state.matchedLocation == '/login';

      // /support is accessible without login (pre-auth support)
      final onSupport   = state.matchedLocation == '/support';
      final onRegister  = state.matchedLocation == '/register';
      if (onSupport || onRegister) return null;

      if (!isLoggedIn && !onAuthPage) return '/login';
      if (isLoggedIn && onAuthPage) return '/feed';
      return null;
    },
    routes: [
      // ── Auth (no shell / no bottom bar) ──────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Register — accessible pre-login ──────────────────
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Support — accessible pre-login and post-login ─────
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (_, __) => const SupportScreen(),
      ),

      // ── Shell (bottom bar shown on ALL routes inside) ─────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            name: 'feed',
            builder: (_, __) => const FeedScreen(),
          ),
          GoRoute(
            path: '/my-requests',
            name: 'my_requests',
            builder: (_, __) => const MyRequestsScreen(),
          ),
          GoRoute(
            path: '/donors',
            name: 'donors',
            builder: (_, __) => const DonorsScreen(),
          ),
          GoRoute(
            path: '/directory',
            name: 'directory',
            builder: (_, __) => const DirectoryScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          // Notifications moved INSIDE the shell so bottom bar shows
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          // Add Requirement moved INSIDE the shell so bottom bar shows
          GoRoute(
            path: '/add-requirement',
            name: 'add_requirement',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddRequirementScreen(
                existing: extra?['existing'],
              );
            },
          ),
          // Edit Profile inside shell
          GoRoute(
            path: '/edit-profile',
            name: 'edit_profile',
            builder: (_, __) => const EditProfileScreen(),
          ),
        ],
      ),

      // ── Full-screen routes (no shell / no bottom bar) ─────
      GoRoute(
        path: '/requirement/:id',
        name: 'requirement_detail',
        builder: (context, state) {
          final id    = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return RequirementDetailScreen(
            requirementId: id,
            requirement:   extra?['requirement'],
          );
        },
      ),
      GoRoute(
        path: '/accepted',
        name: 'accepted',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AcceptedScreen(
            hospital:      extra?['hospital']      as String? ?? '',
            contactPerson: extra?['contactPerson'] as String? ?? '',
            contactPhone:  extra?['contactPhone']  as String? ?? '',
            location:      extra?['location']      as String? ?? '',
            bloodType:     extra?['bloodType']     as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/feed',
      ),
    ],
  );
});
