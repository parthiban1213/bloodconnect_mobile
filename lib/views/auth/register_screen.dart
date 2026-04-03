import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../utils/api_exception.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/blood_drop_widget.dart';

// ─── Registration steps ───────────────────────────────────────────────────────
enum _RegStep { mobile, otpCode, details }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  _RegStep _step = _RegStep.mobile;

  // ── Mobile + OTP ─────────────────────────────────────────
  final _mobileCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _timerSec = AppConfig.otpTimerSeconds;
  bool _timerActive = false;
  bool _otpSending = false;
  bool _otpVerifying = false;

  // ── Details form ─────────────────────────────────────────
  final _usernameCtrl  = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();
  String? _selectedBloodType;
  DateTime? _lastDonationDate;
  bool _isAvailable = true;
  bool _registering = false;

  // ── Errors / success ─────────────────────────────────────
  String? _error;
  String? _mobileError;
  bool _mobileVerified = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpNodes) f.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Step navigation ───────────────────────────────────────
  void _goStep(_RegStep s) => setState(() { _step = s; _error = null; });

  // ── Timer ─────────────────────────────────────────────────
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

  // ── Send OTP (register purpose) ───────────────────────────
  Future<void> _sendOtp() async {
    final m = _mobileCtrl.text.trim();
    if (m.isEmpty) {
      setState(() => _mobileError = AppConfig.regErrMobileEmpty);
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(m)) {
      setState(() =>
          _mobileError = AppConfig.regErrMobileInvalid);
      return;
    }
    setState(() { _mobileError = null; _otpSending = true; _error = null; });
    try {
      await AuthService().sendOtpForRegister(m);
      if (!mounted) return;
      for (final c in _otpCtrls) c.clear();
      _goStep(_RegStep.otpCode);
      _startTimer();
      Future.delayed(const Duration(milliseconds: 80),
          () => _otpNodes[0].requestFocus());
    } on MobileAlreadyExistsException catch (e) {
      if (mounted) {
        setState(() => _mobileError = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _otpSending = false);
    }
  }

  // ── Verify OTP ────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length < 6) return;
    setState(() { _otpVerifying = true; _error = null; });
    try {
      await AuthService().verifyRegisterOtp(
          mobile: _mobileCtrl.text.trim(), otp: code);
      if (!mounted) return;
      setState(() { _mobileVerified = true; });
      _goStep(_RegStep.details);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _otpVerifying = false);
    }
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

  Future<void> _resendOtp() async {
    for (final c in _otpCtrls) c.clear();
    setState(() => _error = null);
    await _sendOtp();
  }

  // ── Submit registration ───────────────────────────────────
  Future<void> _submitRegistration() async {
    final username  = _usernameCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName  = _lastNameCtrl.text.trim();
    final email     = _emailCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _error = AppConfig.regErrFirstLast);
      return;
    }
    if (_selectedBloodType == null) {
      setState(() => _error = AppConfig.regErrBloodType);
      return;
    }
    if (username.length < 3) {
      setState(() => _error = AppConfig.regErrUsername);
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = AppConfig.regErrEmailRequired);
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(email)) {
      setState(() => _error = AppConfig.regErrEmail);
      return;
    }

    setState(() { _registering = true; _error = null; });
    try {
      final mobile = _mobileCtrl.text.trim();
      final otp    = _otpCtrls.map((c) => c.text).join();

      final result = await AuthService().registerDirect(
        mobile:           mobile,
        otp:              otp,
        username:         username,
        firstName:        firstName,
        lastName:         lastName,
        bloodType:        _selectedBloodType!,
        email:            email,
        address:          _addressCtrl.text.trim().isNotEmpty
                              ? _addressCtrl.text.trim()
                              : null,
        lastDonationDate: _lastDonationDate,
      );

      // Save token + update auth state
      await ref
          .read(authViewModelProvider.notifier)
          .loginFromRegistration(result.token, result.user);

      if (mounted) context.go('/feed');
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonationDate ?? now.subtract(const Duration(days: 90)),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _lastDonationDate = picked);
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: switch (_step) {
            _RegStep.mobile  => _buildMobileStep(),
            _RegStep.otpCode => _buildOtpStep(),
            _RegStep.details => _buildDetailsStep(),
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 1 — Enter mobile
  // ══════════════════════════════════════════════════════════
  Widget _buildMobileStep() {
    return _RegLayout(
      key: const ValueKey('step-mobile'),
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BloodDropWidget(size: 80),
          const SizedBox(height: 12),
          Text('HSBlood',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          Text(AppConfig.regBrandSub,
            style: GoogleFonts.syne(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.primary, letterSpacing: 1.5)),
        ],
      ),
      bottomContent: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppConfig.regHeading,
              style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(AppConfig.regSubtext,
              style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // Info hint
            _HintCard(
              icon: Icons.phone_android_rounded,
              body: AppConfig.regHintBody,
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              _ErrorPill(_error!), const SizedBox(height: 10),
            ],
            if (_mobileError != null) ...[
              _ErrorPill(_mobileError!), const SizedBox(height: 10),
            ],

            // Mobile field
            _MobileField(ctrl: _mobileCtrl, onSubmit: _sendOtp),
            const SizedBox(height: 16),

            // Send OTP button
            _PrimaryButton(
              label: AppConfig.regSendOtpBtn,
              icon: Icons.sms_outlined,
              isLoading: _otpSending,
              onTap: _sendOtp,
            ),

            const SizedBox(height: 14),
            _Divider(label: AppConfig.regSignInDivider),
            const SizedBox(height: 14),

            // Back to login
            _OutlineButton(
              label: AppConfig.regSignInBtn,
              onTap: () => context.go('/login'),
            ),

            const SizedBox(height: 16),
            _SupportLink(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 2 — Enter OTP
  // ══════════════════════════════════════════════════════════
  Widget _buildOtpStep() {
    final mobile = _mobileCtrl.text.trim();

    return _RegLayout(
      key: const ValueKey('step-otp'),
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20)),
            child: const Center(
              child: Icon(Icons.mark_email_read_outlined,
                size: 28, color: AppColors.primary)),
          ),
          const SizedBox(height: 14),
          Text(AppConfig.regOtpIconTitle,
            style: GoogleFonts.dmSans(
              fontSize: 18, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('${AppConfig.regOtpSentPrefix}$mobile',
            style: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              _timer?.cancel();
              _goStep(_RegStep.mobile);
            },
            child: Text(AppConfig.regOtpChangeNumber,
              style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.primary,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary)),
          ),
        ],
      ),
      bottomContent: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppConfig.regOtpHeading,
              style: GoogleFonts.dmSans(
                fontSize: 20, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(AppConfig.regOtpSubtext,
              style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            if (_error != null) ...[
              _ErrorPill(_error!), const SizedBox(height: 12),
            ],

            // OTP cells
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _OtpCell(
                ctrl: _otpCtrls[i],
                node: _otpNodes[i],
                onInput: (v) => _onOtpInput(i, v),
                onBackspace: () => _onOtpBackspace(i),
              )),
            ),
            const SizedBox(height: 20),

            _PrimaryButton(
              label: AppConfig.regVerifyBtn,
              icon: Icons.verified_user_outlined,
              isLoading: _otpVerifying,
              onTap: _verifyOtp,
            ),
            const SizedBox(height: 16),

            // Resend / timer
            Center(
              child: _timerActive
                ? Text(
                    '${AppConfig.regResendTimerPrefix}${_timerSec}${AppConfig.regResendTimerSuffix}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted))
                : GestureDetector(
                    onTap: _resendOtp,
                    child: Text(AppConfig.regResendBtn,
                      style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary)),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 3 — Registration details form
  // ══════════════════════════════════════════════════════════
  Widget _buildDetailsStep() {
    return _RegLayout(
      key: const ValueKey('step-details'),
      scrollable: true,
      topContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Verified mobile badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDFBF3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_rounded,
                  size: 15, color: Color(0xFF15803D)),
              const SizedBox(width: 7),
              Text(
                '${_mobileCtrl.text.trim()}${AppConfig.regVerifiedSuffix}',
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: const Color(0xFF15803D))),
            ]),
          ),
          const SizedBox(height: 14),
          Text(AppConfig.regDetailsHeading,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(AppConfig.regDetailsSubtitle,
            style: GoogleFonts.syne(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.primary, letterSpacing: 1.2)),
        ],
      ),
      bottomContent: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              _ErrorPill(_error!), const SizedBox(height: 14),
            ],

            // ── Personal Info ─────────────────────────────
            _SectionLabel(label: AppConfig.regSectionPersonal),
            const SizedBox(height: 10),

            Row(children: [
              Expanded(child: _LabeledField(
                label: AppConfig.regFirstNameLabel,
                child: _PlainField(
                  ctrl: _firstNameCtrl, hint: AppConfig.regFirstNameHint,
                  icon: Icons.person_outline_rounded),
              )),
              const SizedBox(width: 10),
              Expanded(child: _LabeledField(
                label: AppConfig.regLastNameLabel,
                child: _PlainField(
                  ctrl: _lastNameCtrl, hint: AppConfig.regLastNameHint,
                  icon: Icons.person_outline_rounded),
              )),
            ]),
            const SizedBox(height: 12),

            _LabeledField(
              label: AppConfig.regUsernameLabel,
              child: _PlainField(
                ctrl: _usernameCtrl, hint: AppConfig.regUsernameHint,
                icon: Icons.alternate_email_rounded,
                autocorrect: false),
            ),
            const SizedBox(height: 12),

            // ── Donor Info ───────────────────────────────
            _SectionLabel(label: AppConfig.regSectionDonor),
            const SizedBox(height: 10),

            _LabeledField(
              label: AppConfig.regBloodTypeLabel,
              child: _BloodTypeDropdown(
                value: _selectedBloodType,
                onChanged: (v) => setState(() => _selectedBloodType = v),
              ),
            ),
            const SizedBox(height: 12),

            // ── Contact ──────────────────────────────────
            _SectionLabel(label: AppConfig.regSectionContact),
            const SizedBox(height: 10),

            _LabeledField(
              label: AppConfig.regEmailLabel,
              child: _PlainField(
                ctrl: _emailCtrl, hint: AppConfig.regEmailHint,
                icon: Icons.mail_outline_rounded,
                keyboard: TextInputType.emailAddress,
                autocorrect: false),
            ),
            const SizedBox(height: 12),

            _LabeledField(
              label: AppConfig.regAddressLabel,
              child: _PlainField(
                ctrl: _addressCtrl, hint: AppConfig.regAddressHint,
                icon: Icons.location_on_outlined),
            ),
            const SizedBox(height: 12),

            // ── Optional ─────────────────────────────────
            _SectionLabel(label: AppConfig.regSectionOptional),
            const SizedBox(height: 10),

            // Last donation date picker
            _LabeledField(
              label: AppConfig.regLastDonationLabel,
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      _lastDonationDate == null
                          ? AppConfig.regLastDonationHint
                          : '${_lastDonationDate!.day.toString().padLeft(2, '0')}/'
                            '${_lastDonationDate!.month.toString().padLeft(2, '0')}/'
                            '${_lastDonationDate!.year}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: _lastDonationDate == null
                            ? AppColors.textVeryMuted
                            : AppColors.textPrimary))),
                    if (_lastDonationDate != null) ...[
                      GestureDetector(
                        onTap: () => setState(() => _lastDonationDate = null),
                        child: const Icon(Icons.clear_rounded,
                            size: 16, color: AppColors.textMuted)),
                      const SizedBox(width: 12),
                    ],
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            _PrimaryButton(
              label: AppConfig.regSubmitBtn,
              isLoading: _registering,
              onTap: _submitRegistration,
            ),
            const SizedBox(height: 12),

            // Back
            _OutlineButton(
              label: AppConfig.regBackBtn,
              onTap: () {
                setState(() { _error = null; });
                _goStep(_RegStep.otpCode);
              },
            ),
            const SizedBox(height: 16),
            _SupportLink(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Shared layout wrapper
// ══════════════════════════════════════════════════════════════
class _RegLayout extends StatelessWidget {
  final Widget topContent;
  final Widget bottomContent;
  final bool scrollable;

  const _RegLayout({
    super.key,
    required this.topContent,
    required this.bottomContent,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Top gradient band with brand / step indicator
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFDF5F6),
                          AppColors.background,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    child: Center(child: topContent),
                  ),

                  // White card bottom
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                      ),
                      child: bottomContent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Reusable widgets (matching login_screen.dart style exactly)
// ══════════════════════════════════════════════════════════════

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
          ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label,
                  style: GoogleFonts.syne(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
              ],
            ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

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
  final TextInputType keyboard;
  final TextInputAction action;
  final bool autocorrect;

  const _PlainField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.action = TextInputAction.next,
    this.autocorrect = true,
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
            keyboardType: keyboard,
            textInputAction: action,
            autocorrect: autocorrect,
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
        const SizedBox(width: 16),
      ]),
    );
  }
}

class _BloodTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  static const _types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  const _BloodTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(AppConfig.regBloodTypeHint,
            style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textVeryMuted)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted),
          isExpanded: true,
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textPrimary),
          onChanged: onChanged,
          items: _types.map((t) => DropdownMenuItem(
            value: t,
            child: Row(children: [
              Container(
                width: 32, height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6)),
                child: Center(
                  child: Text(t,
                    style: GoogleFonts.syne(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.primary)))),
              const SizedBox(width: 10),
              Text(t, style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary)),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AvailabilityToggle(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(6),
      child: Row(children: [
        Expanded(child: _ToggleOption(
          label: AppConfig.regAvailableOption,
          selected: value,
          onTap: () => onChanged(true),
        )),
        const SizedBox(width: 6),
        Expanded(child: _ToggleOption(
          label: AppConfig.regUnavailableOption,
          selected: !value,
          onTap: () => onChanged(false),
        )),
      ]),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(label,
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary))),
      ),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
        style: GoogleFonts.syne(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.3)),
      const SizedBox(height: 6),
      child,
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(label,
        style: GoogleFonts.syne(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8)),
    );
  }
}

class _HintCard extends StatelessWidget {
  final IconData icon;
  final String body;

  const _HintCard({required this.icon, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(body,
          style: GoogleFonts.dmSans(
            fontSize: 12, color: AppColors.textSecondary, height: 1.5))),
      ]),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  final String msg;
  const _ErrorPill(this.msg);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 12, color: AppColors.textMuted))),
      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
    ]);
  }
}

class _SupportLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => context.push('/support'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline_rounded,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(AppConfig.supportLabel,
              style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.primary,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
