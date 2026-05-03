import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';
import 'utils/app_config.dart';
import 'utils/firebase_options.dart';
import 'views/auth/splash_screen.dart';
import 'services/fcm_service.dart';
import 'services/app_update_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialise Remote Config defaults + fetch latest values.
  await AppUpdateService.initialize();

  // Register background FCM handler before runApp
  await FcmService.setupBackground();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

class _BloodConnectAppState extends ConsumerState<BloodConnectApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ── Auth state listener ───────────────────────────────
      // Fires on every auth state change after this widget is built.
      // Handles: login, logout, blood type profile change.
      ref.listenManual<AuthState>(authViewModelProvider, (previous, next) {
        if (!next.isLoggedIn) {
          // Logged out — clean up FCM subscriptions
          if (previous?.isLoggedIn == true) {
            FcmService().unsubscribeAll();
          }
          return;
        }

        // Logged in (either just now, or blood type / profile changed)
        // Always call ensureInitialized so:
        //  - topic subscription is verified / re-established
        //  - FCM token is saved to backend (retried if it failed before)
        final bloodType = next.user?.bloodType ?? '';
        FcmService().ensureInitialized(bloodType: bloodType, username: next.user?.username ?? '');
      });

      // ── Cold-start: already logged in ────────────────────
      // The listenManual above only fires on CHANGES. If the user was
      // already logged in when the app started, _checkAuth sets
      // isLoggedIn=true but the listener may have missed it (depends on
      // whether _checkAuth completed before addPostFrameCallback ran).
      // Read current state and init FCM directly as a safety net.
      final authState = ref.read(authViewModelProvider);
      if (authState.isLoggedIn) {
        FcmService().ensureInitialized(
          bloodType: authState.user?.bloodType ?? '',
          username:  authState.user?.username  ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── App resume ───────────────────────────────────────────
  // Called every time the app comes back to the foreground.
  // Two things happen:
  //   1. Session is re-validated (catches deleted accounts).
  //   2. FCM is re-initialized — this retries a failed token save
  //      and re-confirms the topic subscription. This is the key fix
  //      for both notification failures: even if the token save failed
  //      at login time (Render cold start, network blip), it succeeds
  //      here the next time the user opens the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authVm = ref.read(authViewModelProvider.notifier);
      authVm.validateSessionOnResume();

      // Re-run FCM init on every resume to retry failed token saves
      // and re-confirm topic subscriptions.
      final authState = ref.read(authViewModelProvider);
      if (authState.isLoggedIn) {
        FcmService().ensureInitialized(
          bloodType: authState.user?.bloodType ?? '',
          username:  authState.user?.username  ?? '',
        );
      }
    }
  }

  // ── Hardware back button handler ─────────────────────────
  // WidgetsBindingObserver.didPopRoute() is called on every
  // Android back press BEFORE Flutter's widget tree handles it.
  // Returning true means "we handled it — don't close the app".
  //
  // Rules:
  //   • /home            → exit the app (return false → OS handles)
  //   • any other screen → go to /home  (return true  → we handled)
  //   • genuine sub-page → pop normally (return true  → we handled)
  @override
  Future<bool> didPopRoute() async {
    final router = ref.read(routerProvider);
    final location = router.routerDelegate.currentConfiguration
        .matches.last.matchedLocation;

    const homePath = '/home';
    const topLevelPaths = [
      '/home', '/feed', '/my-requests', '/donors',
      '/directory', '/history', '/profile', '/notifications',
      '/add-requirement', '/edit-profile',
    ];

    final isTopLevel = topLevelPaths.any((p) => location.startsWith(p));

    // Genuine sub-page on top (dialog, pushed route) — pop normally.
    if (!isTopLevel && router.canPop()) {
      router.pop();
      return true;
    }

    // On home → let the OS exit the app.
    if (location.startsWith(homePath)) {
      return false;
    }

    // Any other screen → go to home.
    router.go('/home');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final router         = ref.watch(routerProvider);
    final isCheckingAuth = ref.watch(authViewModelProvider).isCheckingAuth;
    return SplashScreen(
      isCheckingAuth: isCheckingAuth,
      child: MaterialApp.router(
        title: AppConfig.mainAppTitle,
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
