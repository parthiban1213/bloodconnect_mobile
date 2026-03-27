import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../utils/app_config.dart';
import '../../widgets/blood_drop_widget.dart';

// ─────────────────────────────────────────────────────────────
//  Splash Screen
//  Uses BloodDropWidget (assets/images/blood_drop.svg) as the
//  animated centrepiece.
// ─────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  final Widget child;
  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;

  late Animation<double> _dropScale;
  late Animation<double> _dropFade;
  late Animation<double> _textFade;
  late Animation<Offset>  _textSlide;
  late Animation<double> _tagFade;
  late Animation<double> _exitFade;

  bool _done = false;
  // Once true the overlay widget is removed from the tree entirely.
  bool _overlayGone = false;

  late AnimationController _exitCtrl;
  late Animation<double>   _overlayFade;

  @override
  void initState() {
    super.initState();
    // Request notification permission on launch for all OS versions
    _requestNotificationPermission();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));

    _dropScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.00, 0.42, curve: Curves.elasticOut)));

    _dropFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.00, 0.20, curve: Curves.easeIn)));

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.35, 0.56, curve: Curves.easeOut)));

    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.30), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.35, 0.56, curve: Curves.easeOut)));

    _tagFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.54, 0.72, curve: Curves.easeIn)));

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.82, 1.00, curve: Curves.easeInOut)));

    // Short controller that fades the white overlay OUT after widget.child
    // has had two frames to render — eliminates the black flash entirely.
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _overlayFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeOut));
    _exitCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _overlayGone = true);
      }
    });

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2750), () {
      if (!mounted) return;
      setState(() => _done = true);
      // Give widget.child two frames to paint before fading the overlay away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _exitCtrl.forward();
        });
      });
    });
  }

  Future<void> _requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once the overlay has fully faded, remove it from the tree.
    if (_overlayGone) return widget.child;

    // Always render widget.child at the bottom of the stack so it has time
    // to build and paint before the white overlay fades away. This prevents
    // the black flash that occurs when switching directly to an unrendered child.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // ── App content (renders behind the overlay) ──────────
          widget.child,

          // ── Splash overlay ────────────────────────────────────
          // Fades out via _exitCtrl after child has painted two frames.
          FadeTransition(
            opacity: _done ? _overlayFade : const AlwaysStoppedAnimation(1.0),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _exitFade.value,
                child: Material(
                  color: Colors.white,
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Blood drop asset ───────────────────
                          FadeTransition(
                            opacity: _dropFade,
                            child: ScaleTransition(
                              scale: _dropScale,
                              alignment: Alignment.center,
                              child: const BloodDropWidget(size: 110),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Brand name ─────────────────────────
                          FadeTransition(
                            opacity: _textFade,
                            child: SlideTransition(
                              position: _textSlide,
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(text: AppConfig.splashBrandBold,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 34, fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: -0.5)),
                                  TextSpan(text: AppConfig.splashBrandLight,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 34, fontWeight: FontWeight.w300,
                                      color: const Color(0xFF444444),
                                      letterSpacing: -0.5)),
                                ]),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Tagline ────────────────────────────
                          FadeTransition(
                            opacity: _tagFade,
                            child: Text(AppConfig.splashTagline,
                              style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: const Color(0xFFC8102E),
                                letterSpacing: 0.4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
