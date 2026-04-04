import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../utils/app_config.dart';
import '../../widgets/blood_drop_widget.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  final bool isCheckingAuth;

  const SplashScreen({
    super.key,
    required this.child,
    required this.isCheckingAuth,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Intro: drop + text appear (plays once) ────────────────
  late final AnimationController _introCtrl;
  late final Animation<double> _dropScale;
  late final Animation<double> _dropOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset>  _textSlide;
  late final Animation<double> _tagOpacity;

  // ── Pulse: gentle breathing while waiting for auth ────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  // ── Exit: fade out the whole overlay ─────────────────────
  late final AnimationController _exitCtrl;
  late final Animation<double> _overlayOpacity;

  bool _overlayVisible = true;
  bool _introDone      = false;
  bool _exitStarted    = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _setupAnimations();
    _introCtrl.forward();
  }

  void _setupAnimations() {
    // ── Intro (1800 ms) ───────────────────────────────────
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Drop: fade in over first 25%, scale from 0.6→1.0 over first 55%
    // using easeOutBack for a natural settle — no elastic overshoot jank.
    _dropOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.00, 0.25, curve: Curves.easeOut),
      ),
    );
    _dropScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.00, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Brand text: slides up + fades in
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.38, 0.65, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.38, 0.65, curve: Curves.easeOut),
      ),
    );

    // Tagline
    _tagOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
      ),
    );

    _introCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _introDone = true;
        if (!widget.isCheckingAuth) {
          _startExit();
        } else {
          _pulseCtrl.repeat(reverse: true);
        }
      }
    });

    // ── Pulse (700 ms half-cycle, repeating) ──────────────
    // Scale 1.0 → 1.08, smooth ease in-out. Independent controller
    // so it never interferes with intro or exit timing.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ── Exit (280 ms) ─────────────────────────────────────
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _overlayOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
    _exitCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _removeOverlay();
    });
  }

  void _startExit() {
    if (_exitStarted || !mounted) return;
    _exitStarted = true;

    // Stop pulse and let it settle to 1.0 before fading out.
    if (_pulseCtrl.isAnimating) {
      _pulseCtrl
          .animateTo(0.0, duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut)
          .whenComplete(() {
        if (mounted) _exitCtrl.forward();
      });
    } else {
      _exitCtrl.forward();
    }
  }

  void _removeOverlay() {
    if (!mounted || !_overlayVisible) return;
    setState(() => _overlayVisible = false);
  }

  @override
  void didUpdateWidget(SplashScreen old) {
    super.didUpdateWidget(old);
    if (old.isCheckingAuth && !widget.isCheckingAuth && _introDone) {
      _startExit();
    }
  }

  Future<void> _requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_overlayVisible) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          AbsorbPointer(
            child: AnimatedBuilder(
              // Each controller drives only its own widgets below —
              // but we merge here so the builder re-runs on any tick.
              animation: Listenable.merge([_introCtrl, _pulseCtrl, _exitCtrl]),
              builder: (context, _) {
                return Opacity(
                  opacity: _overlayOpacity.value,
                  child: Material(
                    color: Colors.white,
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Drop: intro scale + opacity, then pulse scale.
                            // The two scales are kept separate so they never
                            // multiply unexpectedly.
                            Opacity(
                              opacity: _dropOpacity.value,
                              child: Transform.scale(
                                // During intro: _dropScale goes 0.6→1.0.
                                // During pulse: _dropScale is fixed at 1.0
                                //   and _pulseScale does 1.0→1.08.
                                scale: _dropScale.value * _pulseScale.value,
                                alignment: Alignment.center,
                                child: const BloodDropWidget(size: 110),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Opacity(
                              opacity: _textOpacity.value,
                              child: SlideTransition(
                                position: _textSlide,
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: AppConfig.splashBrandBold,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A1A1A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: AppConfig.splashBrandLight,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xFF444444),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Opacity(
                              opacity: _tagOpacity.value,
                              child: Text(
                                AppConfig.splashTagline,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFC8102E),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
