import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';
import 'utils/firebase_options.dart';
import 'views/auth/splash_screen.dart';
import 'services/fcm_service.dart';
import 'viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase init with explicit options ───────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background FCM handler before runApp
  await FcmService.setupBackground();

  // ── Device orientation ────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar style ──────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.dark,
    systemNavigationBarColor:          Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: BloodConnectApp()));
}

class BloodConnectApp extends ConsumerStatefulWidget {
  const BloodConnectApp({super.key});

  @override
  ConsumerState<BloodConnectApp> createState() => _BloodConnectAppState();
}

// WidgetsBindingObserver lets us detect app resume (foreground) events.
// On resume we re-validate the stored token against the server — this covers
// the case where the account was deleted from the backend while the app was
// running or backgrounded. If the server returns 401, _checkAuth clears the
// token and the router redirects to /login automatically.
class _BloodConnectAppState extends ConsumerState<BloodConnectApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen for login/logout to init/teardown FCM
      ref.listenManual<AuthState>(authViewModelProvider, (previous, next) {
        if (next.isLoggedIn && !(previous?.isLoggedIn ?? false)) {
          FcmService().init(bloodType: next.user?.bloodType ?? '');
        } else if (next.isLoggedIn && previous?.isLoggedIn == true) {
          final bt = next.user?.bloodType ?? '';
          if (bt.isNotEmpty) FcmService().init(bloodType: bt);
        } else if (!next.isLoggedIn && (previous?.isLoggedIn ?? false)) {
          FcmService().unsubscribeAll();
        }
      });

      // Already logged in on cold start — init FCM immediately.
      final authState = ref.read(authViewModelProvider);
      if (authState.isLoggedIn) {
        FcmService().init(bloodType: authState.user?.bloodType ?? '');
      }

      // Retry init after a short delay to catch delayed auth restoration.
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        final s = ref.read(authViewModelProvider);
        if (s.isLoggedIn) {
          FcmService().init(bloodType: s.user?.bloodType ?? '');
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called whenever the app transitions to the foreground (resumed from
  // background or lock screen). We re-run _checkAuth so a deleted/revoked
  // account is caught immediately on next open — not just on cold start.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authVm = ref.read(authViewModelProvider.notifier);
      authVm.validateSessionOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router         = ref.watch(routerProvider);
    final isCheckingAuth = ref.watch(authViewModelProvider).isCheckingAuth;
    return SplashScreen(
      // Keep the splash overlay visible until _checkAuth completes.
      // Without this, the overlay fades after the animation (≈2.6 s) but
      // _checkAuth may still be running — the router sits on /login during
      // that window, so a logged-in user sees a login screen flash before
      // being redirected to /feed.
      isCheckingAuth: isCheckingAuth,
      child: MaterialApp.router(
        title: 'BloodConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
