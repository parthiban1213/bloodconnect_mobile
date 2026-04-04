import 'package:flutter/material.dart';
import '../../utils/app_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';

// ─────────────────────────────────────────────────────────────
//  Edit Profile Screen
//  Fix [12]: Pre-fills firstName, lastName, mobile, email on open.
//
//  Root cause of previous failure: the screen read user data from
//  in-memory state which might be stale (e.g. firstName/lastName
//  not returned by the login endpoint but available in /profile).
//  Fix: call refreshProfile() in initState so the latest server
//  data is loaded, then populate the controllers once it arrives
//  via a reactive listener rather than a one-shot read.
// ─────────────────────────────────────────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers initialised with empty strings; populated once the
  // profile fetch completes (or immediately if data is already in state).
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _addressCtrl;

  String? _selectedBloodType;
  bool    _controllersFilled = false; // guard: only fill once

  @override
  void initState() {
    super.initState();

    // Create controllers with whatever is already in state right now.
    final user = ref.read(authViewModelProvider).user;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl  = TextEditingController(text: user?.lastName  ?? '');
    _emailCtrl     = TextEditingController(text: user?.email     ?? '');
    _mobileCtrl    = TextEditingController(text: user?.mobile    ?? '');
    _addressCtrl   = TextEditingController(text: user?.address   ?? '');
    _selectedBloodType =
        (user?.bloodType.isNotEmpty == true) ? user!.bloodType : null;

    // Mark filled if we already have the data, otherwise wait for the
    // refresh below to complete.
    _controllersFilled = user?.firstName?.isNotEmpty == true ||
                         user?.lastName?.isNotEmpty  == true ||
                         user?.mobile?.isNotEmpty    == true;

    // Fetch fresh profile data from the server so fields show latest values.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authViewModelProvider.notifier).refreshProfile();
      // After refresh, populate controllers with the freshly loaded data.
      if (mounted) _fillControllers();
    });
  }

  void _fillControllers() {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    // Only update a controller if the incoming value is non-empty,
    // to avoid wiping something the user may have already typed.
    if ((user.firstName ?? '').isNotEmpty && _firstNameCtrl.text.isEmpty) {
      _firstNameCtrl.text = user.firstName!;
    }
    if ((user.lastName ?? '').isNotEmpty && _lastNameCtrl.text.isEmpty) {
      _lastNameCtrl.text = user.lastName!;
    }
    if (user.email.isNotEmpty && _emailCtrl.text.isEmpty) {
      _emailCtrl.text = user.email;
    }
    if ((user.mobile ?? '').isNotEmpty && _mobileCtrl.text.isEmpty) {
      _mobileCtrl.text = user.mobile!;
    }
    if (user.address.isNotEmpty && _addressCtrl.text.isEmpty) {
      _addressCtrl.text = user.address;
    }
    if (_selectedBloodType == null && user.bloodType.isNotEmpty) {
      setState(() => _selectedBloodType = user.bloodType);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    context.dismissKeyboard();

    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'firstName': _firstNameCtrl.text.trim(),
      'lastName':  _lastNameCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'address':   _addressCtrl.text.trim(),
    };
    if (_selectedBloodType != null) data['bloodType'] = _selectedBloodType;
    if (_mobileCtrl.text.trim().isNotEmpty) data['mobile'] = _mobileCtrl.text.trim();

    final ok = await ref.read(authViewModelProvider.notifier).updateProfile(data);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppConfig.editProfileSuccess, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.secondary));
      context.pop();
    } else {
      final err = ref.read(authViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Update failed.', style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.primary));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for refreshProfile to complete and fill controllers
    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (prev?.isLoading == true && next.isLoading == false && next.user != null) {
        _fillControllers();
      }
    });

    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [

          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.chevron_left_rounded,
                    size: 22, color: AppColors.primary)),
              const SizedBox(width: 8),
              Text(AppConfig.editProfileTitle,
                style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                children: [

                  // ── Personal info fields ──────────────────────
                  _FieldCard(children: [
                    _Row(
                      label: AppConfig.editProfileFirstName,
                      child: _EditTextField(
                        ctrl: _firstNameCtrl,
                        hint: AppConfig.editProfileFirstHint,
                        cap: TextCapitalization.words)),
                    _Row(
                      label: AppConfig.editProfileLastName,
                      child: _EditTextField(
                        ctrl: _lastNameCtrl,
                        hint: AppConfig.editProfileLastHint,
                        cap: TextCapitalization.words)),
                    _Row(
                      label: AppConfig.editProfileEmail,
                      child: _EditTextField(
                        ctrl: _emailCtrl,
                        hint: AppConfig.editProfileEmailHint,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && !v.contains('@'))
                            return 'Enter a valid email';
                          return null;
                        })),
                    _Row(
                      label: AppConfig.editProfileMobile,
                      child: _EditTextField(
                        ctrl: _mobileCtrl,
                        hint: AppConfig.editProfileMobileHint,
                        keyboard: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly])),
                    _Row(
                      label: AppConfig.editProfileAddress,
                      isLast: true,
                      child: _EditTextField(
                        ctrl: _addressCtrl,
                        hint: AppConfig.editProfileAddressHint,
                        maxLines: 2)),
                  ]),
                  const SizedBox(height: 12),

                  // ── Blood type ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: const Border.fromBorderSide(
                          BorderSide(color: AppColors.border))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(AppConfig.editProfileBloodType,
                        style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w500,
                          color: AppColors.textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: AppConstants.bloodTypes.map((bt) {
                          final sel = _selectedBloodType == bt;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedBloodType = bt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.urgentBg : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.fromBorderSide(BorderSide(
                                  color: sel ? AppColors.primary : AppColors.border,
                                  width: sel ? 2.0 : 1.5))),
                              child: Text(bt,
                                style: GoogleFonts.dmSans(fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: sel ? AppColors.primary : AppColors.textSecondary)),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Save ──────────────────────────────────────
                  GestureDetector(
                    onTap: isLoading ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: isLoading
                            ? AppColors.primary.withOpacity(0.6)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(16)),
                      child: Center(child: isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(AppConfig.editProfileSaveBtn,
                            style: GoogleFonts.dmSans(fontSize: 14,
                              fontWeight: FontWeight.w500, color: Colors.white))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Card that wraps multiple rows
// ─────────────────────────────────────────────────────────────
class _FieldCard extends StatelessWidget {
  final List<Widget> children;
  const _FieldCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border))),
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Label + field row inside the card
// ─────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isLast;
  const _Row({required this.label, required this.child, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 86,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(label,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
          Expanded(child: child),
        ]),
      ),
      if (!isLast)
        const Divider(height: 1, thickness: 1, color: AppColors.borderSoft, indent: 16),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  Text field — no box decoration, clean inline style
// ─────────────────────────────────────────────────────────────
class _EditTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final int maxLines;
  final TextCapitalization cap;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;

  const _EditTextField({
    required this.ctrl,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
    this.cap = TextCapitalization.none,
    this.formatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      textCapitalization: cap,
      inputFormatters: formatters,
      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textVeryMuted),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      validator: validator,
    );
  }
}
