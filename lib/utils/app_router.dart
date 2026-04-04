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
import '../views/support/support_screen.dart';

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      // Always notify when isCheckingAuth finishes (true → false),
      // regardless of whether isLoggedIn changed. Without this, if the
      // token was wiped (e.g. Android reinstall), isLoggedIn stays false
      // before and after _checkAuth — neither condition below triggers —
      // and the router never re-evaluates its redirect.
      final checkingAuthFinished =
          (previous?.isCheckingAuth == true) && !next.isCheckingAuth;
      if (checkingAuthFinished ||
          previous?.isLoggedIn != next.isLoggedIn ||
          previous?.isCheckingAuth != next.isCheckingAuth) {
        notifyListeners();
      }
    });
  }
  final Ref _ref;
  bool get isLoggedIn     => _ref.read(authViewModelProvider).isLoggedIn;
  bool get isCheckingAuth => _ref.read(authViewModelProvider).isCheckingAuth;
}

final _authRouterNotifierProvider =
    ChangeNotifierProvider<_AuthRouterNotifier>((ref) {
  return _AuthRouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_authRouterNotifierProvider);

  return GoRouter(
    // KEY FIX: start on a blank /splash holding route — NOT /login.
    //
    // Previously the router used initialLocation: '/login' and held
    // everyone there during _checkAuth. This meant LoginScreen was
    // always built and sitting underneath the splash overlay. When
    // _checkAuth finished and the overlay was removed, the user saw
    // LoginScreen for a brief moment before the router redirected to
    // /feed — the "login screen flash" bug.
    //
    // With /splash as the holding route, LoginScreen is never built
    // during _checkAuth. When auth check completes the router goes
    // directly to /feed (if logged in) or /login (if not) — no flash.
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Always accessible without login.
      if (loc == '/support' || loc == '/register') return null;

      // During _checkAuth: stay on the blank /splash holding route.
      // The animated splash overlay (SplashScreen in main.dart) covers
      // this blank screen, so the user sees the splash animation — not
      // a white screen.
      if (notifier.isCheckingAuth) {
        return loc == '/splash' ? null : '/splash';
      }

      final isLoggedIn = notifier.isLoggedIn;

      // Auth check done — /splash has served its purpose. Navigate
      // directly to the correct destination with no intermediate stop.
      if (loc == '/splash') return isLoggedIn ? '/feed' : '/login';

      // Not logged in and not on an auth page → send to login.
      if (!isLoggedIn && loc != '/login') return '/login';

      // Logged in but on login page → send to feed.
      if (isLoggedIn && loc == '/login') return '/feed';

      return null;
    },
    routes: [
      // ── Blank holding route — only active during startup _checkAuth ──
      // Renders nothing; the animated splash overlay covers it entirely.
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const Scaffold(
          backgroundColor: Colors.white,
          body: SizedBox.shrink(),
        ),
      ),

      // ── Auth (no shell / no bottom bar) ──────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Register — accessible pre-login ──────────────────────────
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Support — accessible pre-login and post-login ─────────────
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (_, __) => const SupportScreen(),
      ),

      // ── Shell (bottom bar shown on ALL routes inside) ─────────────
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
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
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
          GoRoute(
            path: '/edit-profile',
            name: 'edit_profile',
            builder: (_, __) => const EditProfileScreen(),
          ),
        ],
      ),

      // ── Full-screen routes (no shell / no bottom bar) ─────────────
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
