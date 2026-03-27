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

class _BloodConnectAppState extends ConsumerState<BloodConnectApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen for login/logout to init/teardown FCM
      ref.listenManual<AuthState>(authViewModelProvider, (previous, next) {
        if (next.isLoggedIn && !(previous?.isLoggedIn ?? false)) {
          // Logged in — init FCM with blood type
          FcmService().init(bloodType: next.user?.bloodType ?? '');
        } else if (next.isLoggedIn && previous?.isLoggedIn == true) {
          // Blood type may have changed (profile update)
          final bt = next.user?.bloodType ?? '';
          if (bt.isNotEmpty) FcmService().init(bloodType: bt);
        } else if (!next.isLoggedIn && (previous?.isLoggedIn ?? false)) {
          // Logged out — unsubscribe
          FcmService().unsubscribeAll();
        }
      });

      // Already logged in on cold start — init FCM immediately.
      // We also schedule a retry after 2 seconds to handle the case where
      // auth state restores from storage slightly after this callback fires.
      final authState = ref.read(authViewModelProvider);
      if (authState.isLoggedIn) {
        FcmService().init(bloodType: authState.user?.bloodType ?? '');
      }

      // Retry init after a short delay to catch delayed auth restoration
      Future.delayed(const Duration(seconds: 2), () {
        final s = ref.read(authViewModelProvider);
        if (s.isLoggedIn) {
          FcmService().init(bloodType: s.user?.bloodType ?? '');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return SplashScreen(
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
