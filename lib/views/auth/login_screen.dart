import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/blood_drop_widget.dart';

enum _LoginView { otp, otpCode, password, forgotPassword }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _LoginView _view    = _LoginView.otp;
  int        _viewIdx = 0;
  bool       _forward = true;

  final _mobileCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int  _timerSec   = AppConfig.otpTimerSeconds;
  bool _timerActive = false;
  String? _mobileError;

  final _userCtrl = TextEditingController();
  final _pwdCtrl  = TextEditingController();
  bool _obscurePwd = true;

  final _fpUserCtrl  = TextEditingController();
  final _fpEmailCtrl = TextEditingController();
  final _fpNewCtrl   = TextEditingController();
  final _fpCfmCtrl   = TextEditingController();
  bool _fpNewObscure = true;
  bool _fpCfmObscure = true;
  bool _fpLoading = false;
  String? _fpError;
  String? _fpSuccess;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpNodes) f.dispose();
    _userCtrl.dispose(); _pwdCtrl.dispose();
    _fpUserCtrl.dispose(); _fpEmailCtrl.dispose();
    _fpNewCtrl.dispose(); _fpCfmCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _go(_LoginView v, {bool forward = true}) {
    ref.read(authViewModelProvider.notifier).clearError();
    _forward = forward;
    setState(() {
      _viewIdx = forward ? _viewIdx + 1 : _viewIdx - 1;
      _view    = v;
      _mobileError = null;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() { _timerSec = AppConfig.otpTimerSeconds; _timerActive = true; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSec <= 1) {
        t.cancel();
        if (mounted) setState(() => _timerActive = false);
      } else {
        if (mounted) setState(() => _timerSec--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final m = _mobileCtrl.text.trim();
    if (m.isEmpty) {
      setState(() => _mobileError = 'Please enter your mobile number.'); return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(m)) {
      setState(() => _mobileError = 'Enter a valid 10-digit Indian mobile number.'); return;
    }
    setState(() => _mobileError = null);
    final ok = await ref.read(authViewModelProvider.notifier).sendOtp(m);
    if (ok && mounted) {
      for (final c in _otpCtrls) c.clear();
      _go(_LoginView.otpCode, forward: true);
      _startTimer();
      Future.delayed(const Duration(milliseconds: 80),
          () => _otpNodes[0].requestFocus());
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length < 6) return;
    final ok = await ref.read(authViewModelProvider.notifier).verifyOtp(code);
    if (ok && mounted) context.go('/feed');
  }

  Future<void> _resendOtp() async {
    for (final c in _otpCtrls) c.clear();
    ref.read(authViewModelProvider.notifier).clearError();
    await ref.read(authViewModelProvider.notifier)
        .sendOtp(ref.read(authViewModelProvider).otpMobile);
    _startTimer();
    Future.delayed(const Duration(milliseconds: 80),
        () => _otpNodes[0].requestFocus());
  }

  void _onOtpInput(int i, String v) {
    if (v.isNotEmpty && i < 5) _otpNodes[i + 1].requestFocus();
    if (v.isNotEmpty && i == 5) {
      _otpNodes[i].unfocus();
      if (_otpCtrls.map((c) => c.text).join().length == 6) _verifyOtp();
    }
  }

  void _onOtpBackspace(int i) {
    if (_otpCtrls[i].text.isEmpty && i > 0) {
      _otpCtrls[i - 1].clear();
      _otpNodes[i - 1].requestFocus();
    }
  }

  Future<void> _doLogin() async {
    final u = _userCtrl.text.trim();
    final p = _pwdCtrl.text;
    if (u.isEmpty || p.isEmpty) return;
    final ok = await ref.read(authViewModelProvider.notifier).login(u, p);
    if (ok && mounted) context.go('/feed');
  }

  Future<void> _doForgot() async {
    setState(() { _fpError = null; _fpSuccess = null; });
    final u = _fpUserCtrl.text.trim();
    final e = _fpEmailCtrl.text.trim();
    final n = _fpNewCtrl.text;
    final c = _fpCfmCtrl.text;
    if (u.isEmpty || e.isEmpty || n.isEmpty || c.isEmpty) {
      setState(() => _fpError = 'Please fill in all fields.'); return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(e)) {
      setState(() => _fpError = 'Please enter a valid email.'); return;
    }
    if (n.length < 6) {
      setState(() => _fpError = 'Password must be at least 6 characters.'); return;
    }
    if (n != c) { setState(() => _fpError = 'Passwords do not match.'); return; }
    setState(() => _fpLoading = true);
    try {
      await ref.read(authViewModelProvider.notifier)
          .forgotPassword(username: u, email: e, newPassword: n);
      if (mounted) {
        setState(() { _fpLoading = false; _fpSuccess = AppConfig.fpSuccessMsg; });
        _fpUserCtrl.clear(); _fpEmailCtrl.clear();
        _fpNewCtrl.clear(); _fpCfmCtrl.clear();
      }
    } catch (err) {
      if (mounted) setState(() {
        _fpLoading = false;
        _fpError = err.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final fwd  = _forward;

    if (auth.isCheckingAuth) {
      return const Scaffold(backgroundColor: Colors.white, body: SizedBox.shrink());
    }

    Widget view = switch (_view) {
      _LoginView.otp => _OtpMobileView(
          key: const ValueKey('otp'),
          ctrl: _mobileCtrl,
          mobileError: _mobileError,
          apiError: auth.error,
          sessionExpired: auth.sessionExpired,
          isSending: auth.otpSending,
          onSend: _sendOtp,
          onToPassword: () => _go(_LoginView.password, forward: true),
          onClearError: () =>
              ref.read(authViewModelProvider.notifier).clearError(),
        ),
      _LoginView.otpCode => _OtpCodeView(
          key: const ValueKey('otp-code'),
          mobile: auth.otpMobile,
          ctrls: _otpCtrls,
          nodes: _otpNodes,
          onInput: _onOtpInput,
          onBackspace: _onOtpBackspace,
          onVerify: _verifyOtp,
          onResend: _resendOtp,
          onBack: () {
            _timer?.cancel();
            ref.read(authViewModelProvider.notifier).resetOtpFlow();
            for (final c in _otpCtrls) c.clear();
            _go(_LoginView.otp, forward: false);
          },
          isVerifying: auth.otpVerifying,
          timerActive: _timerActive,
          timerSec: _timerSec,
          error: auth.error,
        ),
      _LoginView.password => _PasswordView(
          key: const ValueKey('pwd'),
          userCtrl: _userCtrl,
          pwdCtrl: _pwdCtrl,
          obscure: _obscurePwd,
          onToggle: () => setState(() => _obscurePwd = !_obscurePwd),
          onLogin: _doLogin,
          onToOtp: () => _go(_LoginView.otp, forward: false),
          onForgot: () => _go(_LoginView.forgotPassword, forward: true),
          isLoading: auth.isLoading,
          error: auth.error,
        ),
      _LoginView.forgotPassword => _ForgotPasswordView(
          key: const ValueKey('forgot'),
          userCtrl: _fpUserCtrl,
          emailCtrl: _fpEmailCtrl,
          newCtrl: _fpNewCtrl,
          cfmCtrl: _fpCfmCtrl,
          newObscure: _fpNewObscure,
          cfmObscure: _fpCfmObscure,
          onToggleNew: () =>
              setState(() => _fpNewObscure = !_fpNewObscure),
          onToggleCfm: () =>
              setState(() => _fpCfmObscure = !_fpCfmObscure),
          onSubmit: _doForgot,
          onBack: () => _go(_LoginView.password, forward: false),
          isLoading: _fpLoading,
          error: _fpError,
          success: _fpSuccess,
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) {
            final isIn = child.key == view.key;
            final dx = isIn
                ? (fwd ? 1.0 : -1.0)
                : (fwd ? -1.0 : 1.0);
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(dx * 0.22, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          layoutBuilder: (curr, prev) =>
              Stack(children: [...prev, if (curr != null) curr]),
          child: view,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED LAYOUT
// ════════════════════════════════════════════════════════════

class _LoginLayout extends StatelessWidget {
  final Widget topContent;
  final Widget bottomContent;
  final bool scrollable;

  const _LoginLayout({
    required this.topContent,
    required this.bottomContent,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    // Always use a scrollable layout so keyboard never barricades content.
    // LayoutBuilder lets the inner Column fill the available space when the
    // keyboard is hidden, and scroll freely when it is shown.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(child: Center(child: topContent)),
                  bottomContent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VIEW 1: OTP — mobile entry
// ════════════════════════════════════════════════════════════

class _OtpMobileView extends StatelessWidget {
  final TextEditingController ctrl;
  final String? mobileError, apiError;
  final bool isSending, sessionExpired;
  final VoidCallback onSend, onToPassword, onClearError;

  const _OtpMobileView({
    super.key, required this.ctrl,
    this.mobileError, this.apiError,
    required this.isSending, required this.sessionExpired,
    required this.onSend, required this.onToPassword,
    required this.onClearError,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginLayout(
      topContent: BloodDropWidget(size: 90),
      bottomContent: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppConfig.otpHeading.replaceAll('\n', ' '),
              style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            if (sessionExpired) ...[
              _SessionExpiredBanner(), const SizedBox(height: 10),
            ],
            if (apiError != null) ...[
              _ErrorPill(apiError!), const SizedBox(height: 8),
            ],
            if (mobileError != null) ...[
              _ErrorPill(mobileError!), const SizedBox(height: 8),
            ],
            _FieldLabel('Mobile number'),
            const SizedBox(height: 8),
            _MobileField(ctrl: ctrl, onSubmit: onSend),
            const SizedBox(height: 14),
            _LoadingButton(
              label: AppConfig.otpContinueBtn,
              isLoading: isSending,
              onTap: isSending ? null : onSend,
            ),
            const SizedBox(height: 14),
            _OrDivider(),
            const SizedBox(height: 12),
            _SecondaryButton(
                label: AppConfig.otpSwitchBtn, onTap: onToPassword),
            const SizedBox(height: 14),
            _HintCard(
                title: AppConfig.otpHintTitle,
                body: AppConfig.otpHintBody),
            const SizedBox(height: 10),
            _SupportLink(),
            const SizedBox(height: 10),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VIEW 2: OTP — code entry
// ════════════════════════════════════════════════════════════

class _OtpCodeView extends StatelessWidget {
  final String mobile;
  final List<TextEditingController> ctrls;
  final List<FocusNode> nodes;
  final Function(int, String) onInput;
  final Function(int) onBackspace;
  final VoidCallback onVerify, onResend, onBack;
  final bool isVerifying, timerActive;
  final int timerSec;
  final String? error;

  const _OtpCodeView({
    super.key, required this.mobile,
    required this.ctrls, required this.nodes,
    required this.onInput, required this.onBackspace,
    required this.onVerify, required this.onResend, required this.onBack,
    required this.isVerifying, required this.timerActive,
    required this.timerSec, required this.error,
  });

  String get _fmt => mobile.length == 10
      ? '+91 ${mobile.substring(0, 5)} ${mobile.substring(5)}'
      : '+91 $mobile';

  @override
  Widget build(BuildContext context) {
    return _LoginLayout(
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.urgentBg,
              borderRadius: BorderRadius.circular(20)),
            child: const Center(
              child: Icon(Icons.mark_email_read_outlined,
                  color: AppColors.primary, size: 28)),
          ),
          const SizedBox(height: 16),
          Text(AppConfig.otpCodeTitle,
            style: GoogleFonts.dmSans(
              fontSize: 20, fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          RichText(text: TextSpan(
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textSecondary),
            children: [
              TextSpan(text: AppConfig.otpCodeSentTo),
              TextSpan(text: _fmt,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            ],
          )),
        ],
      ),
      bottomContent: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BackLink(label: AppConfig.otpChangeNumber, onTap: onBack),
            const SizedBox(height: 16),
            if (error != null) ...[
              _ErrorPill(error!), const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => Padding(
                padding: EdgeInsets.only(right: i < 5 ? 10 : 0),
                child: _OtpCell(
                  ctrl: ctrls[i], node: nodes[i],
                  onInput: (v) => onInput(i, v),
                  onBackspace: () => onBackspace(i)),
              )),
            ),
            const SizedBox(height: 16),
            timerActive
              ? RichText(text: TextSpan(
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textMuted),
                  children: [
                    TextSpan(text: AppConfig.otpResendTimer),
                    TextSpan(text: '${timerSec}s',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  ]))
              : GestureDetector(
                  onTap: onResend,
                  child: Text(AppConfig.otpResendBtn,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: AppColors.primary))),
            const SizedBox(height: 20),
            _LoadingButton(
              label: AppConfig.otpVerifyBtn,
              isLoading: isVerifying,
              onTap: isVerifying ? null : onVerify,
            ),
            const SizedBox(height: 16),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VIEW 3: Username + Password
// ════════════════════════════════════════════════════════════

class _PasswordView extends StatelessWidget {
  final TextEditingController userCtrl, pwdCtrl;
  final bool obscure, isLoading;
  final VoidCallback onToggle, onLogin, onToOtp, onForgot;
  final String? error;

  const _PasswordView({
    super.key, required this.userCtrl, required this.pwdCtrl,
    required this.obscure, required this.onToggle,
    required this.onLogin, required this.onToOtp, required this.onForgot,
    required this.isLoading, required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginLayout(
      topContent: BloodDropWidget(size: 90),
      bottomContent: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BackLink(label: AppConfig.pwdBackLink, onTap: onToOtp),
            const SizedBox(height: 10),
            Text(AppConfig.pwdHeading.replaceAll('\n', ' '),
              style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            if (error != null) ...[
              _ErrorPill(error!), const SizedBox(height: 10),
            ],
            _FieldLabel('Username'),
            const SizedBox(height: 8),
            _PlainField(
              ctrl: userCtrl, hint: AppConfig.pwdUsernamePlaceholder,
              icon: Icons.person_outline_rounded,
              action: TextInputAction.next, autocorrect: false),
            const SizedBox(height: 12),
            _FieldLabel('Password'),
            const SizedBox(height: 8),
            _PlainField(
              ctrl: pwdCtrl, hint: AppConfig.pwdPasswordPlaceholder,
              icon: Icons.lock_outline_rounded,
              obscure: obscure, onToggleObscure: onToggle,
              action: TextInputAction.done,
              onSubmitted: (_) => onLogin()),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgot,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text(AppConfig.pwdForgotLink,
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 6),
            _LoadingButton(
              label: AppConfig.pwdSignInLabel,
              isLoading: isLoading,
              onTap: isLoading ? null : onLogin,
            ),
            const SizedBox(height: 12),
            _OrDivider(),
            const SizedBox(height: 10),
            _SecondaryButton(
                label: AppConfig.pwdSwitchBtn, onTap: onToOtp),
            const SizedBox(height: 12),
            _HintCard(
                title: AppConfig.pwdHintTitle,
                body: AppConfig.pwdHintBody),
            const SizedBox(height: 10),
            _SupportLink(),
            const SizedBox(height: 10),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VIEW 4: Forgot Password
// ════════════════════════════════════════════════════════════

class _ForgotPasswordView extends StatelessWidget {
  final TextEditingController userCtrl, emailCtrl, newCtrl, cfmCtrl;
  final bool newObscure, cfmObscure, isLoading;
  final VoidCallback onToggleNew, onToggleCfm, onSubmit, onBack;
  final String? error, success;

  const _ForgotPasswordView({
    super.key, required this.userCtrl, required this.emailCtrl,
    required this.newCtrl, required this.cfmCtrl,
    required this.newObscure, required this.cfmObscure,
    required this.onToggleNew, required this.onToggleCfm,
    required this.onSubmit, required this.onBack,
    required this.isLoading, required this.error, required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackLink(label: AppConfig.fpBackLink, onTap: onBack),
          const SizedBox(height: 20),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.urgentBg,
              borderRadius: BorderRadius.circular(18)),
            child: const Center(
              child: Icon(Icons.lock_reset_rounded,
                  color: AppColors.primary, size: 26)),
          ),
          const SizedBox(height: 16),
          Text(AppConfig.fpTitle,
            style: GoogleFonts.dmSans(
              fontSize: 22, fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          if (error != null) ...[
            _ErrorPill(error!), const SizedBox(height: 12),
          ],
          if (success != null) ...[
            _SuccessPill(success!), const SizedBox(height: 12),
          ],
          _FieldLabel('Username'),
          const SizedBox(height: 8),
          _PlainField(
            ctrl: userCtrl, hint: AppConfig.fpUsernamePlaceholder,
            icon: Icons.person_outline_rounded,
            action: TextInputAction.next, autocorrect: false),
          const SizedBox(height: 14),
          _FieldLabel('Email address'),
          const SizedBox(height: 8),
          _PlainField(
            ctrl: emailCtrl, hint: AppConfig.fpEmailPlaceholder,
            icon: Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.next, autocorrect: false),
          const SizedBox(height: 14),
          _FieldLabel('New password'),
          const SizedBox(height: 8),
          _PlainField(
            ctrl: newCtrl, hint: AppConfig.fpNewPwdPlaceholder,
            icon: Icons.lock_outline_rounded,
            obscure: newObscure, onToggleObscure: onToggleNew,
            action: TextInputAction.next),
          const SizedBox(height: 14),
          _FieldLabel('Confirm password'),
          const SizedBox(height: 8),
          _PlainField(
            ctrl: cfmCtrl, hint: AppConfig.fpConfirmPlaceholder,
            icon: Icons.lock_outline_rounded,
            obscure: cfmObscure, onToggleObscure: onToggleCfm,
            action: TextInputAction.done,
            onSubmitted: (_) => onSubmit()),
          const SizedBox(height: 24),
          _LoadingButton(
            label: AppConfig.fpResetBtn,
            isLoading: isLoading,
            onTap: isLoading ? null : onSubmit,
          ),
          const SizedBox(height: 16),
          _HintCard(
              title: AppConfig.fpHintTitle,
              body: AppConfig.fpHintBody),
          const SizedBox(height: 16),
          _Footer(),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  INPUT COMPONENTS
// ════════════════════════════════════════════════════════════

class _MobileField extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSubmit;
  const _MobileField({required this.ctrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(AppConfig.otpCountryFlag,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(AppConfig.otpCountryCode,
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 20, color: AppColors.border),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            style: GoogleFonts.dmSans(
              fontSize: 15, color: AppColors.textPrimary,
              fontWeight: FontWeight.w500, letterSpacing: 1.4),
            decoration: InputDecoration(
              hintText: AppConfig.otpPlaceholder,
              hintStyle: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textVeryMuted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true, contentPadding: EdgeInsets.zero),
          ),
        ),
        const SizedBox(width: 14),
      ]),
    );
  }
}

class _PlainField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboard;
  final TextInputAction action;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;

  const _PlainField({
    required this.ctrl, required this.hint, required this.icon,
    this.obscure = false, this.onToggleObscure,
    this.keyboard = TextInputType.text,
    this.action = TextInputAction.next,
    this.autocorrect = true, this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const SizedBox(width: 16),
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: keyboard,
            textInputAction: action,
            autocorrect: autocorrect,
            onSubmitted: onSubmitted,
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textVeryMuted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true, contentPadding: EdgeInsets.zero),
          ),
        ),
        if (onToggleObscure != null) ...[
          GestureDetector(
            onTap: onToggleObscure,
            child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18, color: AppColors.textMuted)),
          const SizedBox(width: 16),
        ] else
          const SizedBox(width: 16),
      ]),
    );
  }
}

class _OtpCell extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode node;
  final ValueChanged<String> onInput;
  final VoidCallback onBackspace;

  const _OtpCell({
    required this.ctrl, required this.node,
    required this.onInput, required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46, height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.backspace &&
              ctrl.text.isEmpty) onBackspace();
        },
        child: TextField(
          controller: ctrl, focusNode: node,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center, maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onInput,
          style: GoogleFonts.dmSans(
              fontSize: 22, fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            filled: true, fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.border, width: 1.5)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 2)),
            contentPadding: EdgeInsets.zero),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  BUTTON
// ════════════════════════════════════════════════════════════

class _LoadingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _LoadingButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: isLoading || onTap == null
            ? AppColors.primary.withOpacity(0.7)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ))
              : Text(label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String t;
  const _FieldLabel(this.t);
  @override
  Widget build(BuildContext ctx) => Text(t,
    style: GoogleFonts.dmSans(
      fontSize: 11, fontWeight: FontWeight.w500,
      color: AppColors.textSecondary, letterSpacing: 0.3));
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Row(children: [
    Expanded(child: Container(height: 1, color: AppColors.border)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text('or',
        style: GoogleFonts.dmSans(
            fontSize: 11, color: AppColors.textMuted))),
    Expanded(child: Container(height: 1, color: AppColors.border)),
  ]);
}

class _BackLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BackLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.chevron_left_rounded,
          size: 20, color: AppColors.primary),
      Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.primary)),
    ]));
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Center(
    child: Text(AppConfig.footerText,
      style: GoogleFonts.dmSans(
          fontSize: 10, color: AppColors.textVeryMuted)));
}

class _SupportLink extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Center(
    child: GestureDetector(
      onTap: () => ctx.push('/support'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline_rounded,
              size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            AppConfig.supportLabel,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HintCard extends StatelessWidget {
  final String title, body;
  const _HintCard({required this.title, required this.body});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
        style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.primary)),
      const SizedBox(height: 4),
      Text(body,
        style: GoogleFonts.dmSans(
          fontSize: 12, color: AppColors.textSecondary,
          height: 1.5)),
    ]));
}

class _ErrorPill extends StatelessWidget {
  final String msg;
  const _ErrorPill(this.msg);

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.urgentBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.urgentBorder)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          size: 15, color: AppColors.urgentText),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
        style: GoogleFonts.dmSans(
            fontSize: 12, color: AppColors.urgentText, height: 1.4))),
    ]));
}

class _SuccessPill extends StatelessWidget {
  final String msg;
  const _SuccessPill(this.msg);

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFEDFBF3),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFBBF7D0))),
    child: Row(children: [
      const Icon(Icons.check_circle_outline_rounded,
          size: 15, color: Color(0xFF15803D)),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
        style: GoogleFonts.dmSans(
            fontSize: 12, color: const Color(0xFF15803D), height: 1.4))),
    ]));
}

class _SessionExpiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.moderateBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.moderateBorder)),
    child: Row(children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: AppColors.moderateAccent,
          borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.warning_amber_rounded,
            size: 13, color: Colors.white)),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppConfig.sessionExpiredTitle,
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: AppColors.moderateText)),
          Text(AppConfig.sessionExpiredBody,
            style: GoogleFonts.dmSans(
              fontSize: 11, color: AppColors.moderateText, height: 1.4)),
        ])),
    ]));
}
