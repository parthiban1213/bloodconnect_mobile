import 'package:flutter/material.dart';
import '../../utils/app_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_extensions.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../services/reminder_service.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/gamification_viewmodel.dart';
import '../../models/gamification_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authViewModelProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authVm    = ref.read(authViewModelProvider.notifier);
    final user      = authState.user;

    if (user == null && authState.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
            children: List.generate(5, (_) => const CardShimmer()),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Profile hero ────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.navBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        user?.initials ?? '?',
                        style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? '',
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user?.username ?? ''}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        if (user?.bloodType.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Blood Type: ${user!.bloodType}',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.urgentAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 10),

              // ── Units donated card ───────────────────────
              _DonationStatCard(count: user?.donationCount ?? 0),
              const SizedBox(height: 10),

              // ── Gamification — XP, badges, rank ───────────
              _ProfileGamificationSection(
                  donationCount: user?.donationCount ?? 0),
              const SizedBox(height: 10),

              // ── Menu ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    iconBg: AppColors.plannedBg,
                    iconColor: AppColors.plannedText,
                    label: AppConfig.profileEditProfile,
                    value: user?.email.isNotEmpty == true ? user!.email : null,
                    onTap: () => context.push('/edit-profile'),
                    showDivider: true,
                  ),
                  _MenuItem(
                    icon: Icons.bloodtype_outlined,
                    iconBg: AppColors.urgentBg,
                    iconColor: AppColors.urgentText,
                    label: AppConfig.profileBloodType,
                    value: user?.bloodType.isNotEmpty == true
                        ? user!.bloodType
                        : AppConfig.profileNotSet,
                    onTap: null,
                    showDivider: true,
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    iconBg: AppColors.closedBg,
                    iconColor: AppColors.closedText,
                    label: AppConfig.profileChangePassword,
                    onTap: () => _showChangePasswordDialog(context, ref),
                    showDivider: false,
                  ),
                ]),
              ),

              const SizedBox(height: 10),

              // ── Sign out ─────────────────────────────────
              GestureDetector(
                onTap: () => _confirmLogout(context, authVm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.urgentBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.urgentBorder),
                  ),
                  child: Center(
                    child: Text(
                      AppConfig.profileSignOut,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.urgentText,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Delete account — hidden for admins ────────
              if (user?.isAdmin != true) ...[
                const SizedBox(height: 10),
                _DeleteAccountSection(
                  onDelete: () => _confirmDeleteAccount(context, authVm),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppConfig.profileSignOutTitle,
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(AppConfig.profileSignOutBody,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppConfig.profileSignOutCancel,
                style: GoogleFonts.dmSans(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppConfig.profileSignOutConfirm,
                style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed == true) {
      await vm.logout();
      if (context.mounted) context.go('/login');
    }
  }

  // ── Delete account confirmation dialog ───────────────────────
  // Two-step confirmation: first dialog warns, second confirms with
  // destructive styling — mirrors the HS_Blood web confirmDeleteAccount flow.
  Future<void> _confirmDeleteAccount(
      BuildContext context, AuthViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.urgentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            AppConfig.profileDeleteAccountTitle,
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConfig.profileDeleteWarning,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            _BulletRow(text: AppConfig.profileDeleteBullet1),
            _BulletRow(text: AppConfig.profileDeleteBullet2),
            _BulletRow(text: AppConfig.profileDeleteBullet3),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.urgentBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.urgentBorder),
              ),
              child: Text(
                AppConfig.profileDeleteIrreversible,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.urgentText),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppConfig.profileDeleteAccountCancel,
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.urgentBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              AppConfig.profileDeleteAccountConfirm,
              style: GoogleFonts.syne(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Perform deletion
    final ok = await vm.deleteAccount();

    if (!context.mounted) return;
    if (ok) {
      // Account wiped — navigate to login
      context.go('/login');
    } else {
      final errMsg = ref.read(authViewModelProvider).error ??
          AppConfig.profileDeleteFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errMsg),
        backgroundColor: AppColors.primary,
      ));
    }
  }

  Future<void> _showChangePasswordDialog(
      BuildContext context, WidgetRef ref) async {
    final outerContext = context;
    final ok = await showDialog<bool>(
      context: outerContext,
      builder: (_) => _ChangePasswordDialog(ref: ref),
    );
    if (!outerContext.mounted) return;
    if (ok == true) {
      ScaffoldMessenger.of(outerContext).showSnackBar(SnackBar(
        content: Text(AppConfig.profilePwdChanged),
        backgroundColor: AppColors.secondary,
      ));
    } else if (ok == false) {
      ScaffoldMessenger.of(outerContext).showSnackBar(SnackBar(
        content: Text(AppConfig.profilePwdChangeFailed),
        backgroundColor: AppColors.primary,
      ));
    }
  }
}

// ── Delete Account section ────────────────────────────────────
// Shown below the Sign Out button — hidden for admin accounts.
// Styled as a low-profile danger zone so it's discoverable but not alarming.
class _DeleteAccountSection extends StatelessWidget {
  final VoidCallback onDelete;

  const _DeleteAccountSection({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.urgentBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.profileDeleteAccount,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              Text(
                AppConfig.profileDeleteRemoves,
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.urgentBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.urgentBorder),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.syne(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.urgentText),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Bullet row (used in delete confirmation dialog) ───────────
class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ── Units Donated card ────────────────────────────────────────
class _DonationStatCard extends StatelessWidget {
  final int count;
  const _DonationStatCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.urgentBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.bloodtype_outlined,
                size: 22, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.profileDonationLabel.replaceAll('\n', ' '),
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                '$count unit${count == 1 ? '' : 's'}',
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppConfig.profileThankYou,
              style: GoogleFonts.syne(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Donation Eligibility Card ─────────────────────────────────
class _DonationEligibilityCard extends StatelessWidget {
  final DateTime? lastDonationDate;

  const _DonationEligibilityCard({this.lastDonationDate});

  @override
  Widget build(BuildContext context) {
    final nextDate = ReminderService.nextEligibleDate(lastDonationDate);
    final daysLeft = ReminderService.daysUntilEligible(lastDonationDate);
    final isEligible = ReminderService.isEligible(lastDonationDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isEligible ? AppColors.secondaryLight : AppColors.moderateBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Icon(
                  isEligible
                      ? Icons.volunteer_activism_rounded
                      : Icons.hourglass_top_rounded,
                  size: 18,
                  color: isEligible ? AppColors.secondary : AppColors.moderateAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppConfig.profileGamDonationElig,
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 14),
          if (lastDonationDate != null) ...[
            _EligibilityRow(
              icon: Icons.favorite_outline_rounded,
              label: AppConfig.profileLastDonation.replaceAll(': ', ''),
              value: DateFormat('d MMM yyyy').format(lastDonationDate!),
            ),
            const SizedBox(height: 10),
          ],
          _EligibilityRow(
            icon: Icons.event_available_rounded,
            label: AppConfig.profileNextEligible,
            value: isEligible
                ? AppConfig.profileGamNow
                : (nextDate != null
                    ? DateFormat('d MMM yyyy').format(nextDate)
                    : '—'),
            valueColor: isEligible ? AppColors.secondary : AppColors.textPrimary,
          ),
          const SizedBox(height: 10),
          _EligibilityRow(
            icon: Icons.timer_outlined,
            label: AppConfig.profileDaysUntil,
            value: isEligible ? AppConfig.profileGamEligibleNow : '$daysLeft days',
            valueColor: isEligible ? AppColors.secondary : AppColors.moderateAccent,
          ),
        ],
      ),
    );
  }
}

class _EligibilityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _EligibilityRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.textMuted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: valueColor ?? AppColors.textPrimary,
        ),
      ),
    ]);
  }
}

// ── Menu item ─────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.value,
    this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textPrimary)),
                  if (value != null)
                    Text(value!,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textMuted),
          ]),
        ),
      ),
      if (showDivider)
        const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSoft,
            indent: 15),
    ]);
  }
}

// ── Change Password Dialog ────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ChangePasswordDialog({required this.ref});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    context.dismissKeyboard();
    final ok = await widget.ref
        .read(authViewModelProvider.notifier)
        .changePassword(_newCtrl.text, _confirmCtrl.text);
    if (mounted) Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        AppConfig.profileChangePwdTitle,
        style: GoogleFonts.syne(
            fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _PwdField(controller: _newCtrl, label: AppConfig.profileNewPwdLabel),
          const SizedBox(height: 10),
          _PwdField(
            controller: _confirmCtrl,
            label: AppConfig.profileConfirmPwdLabel,
            validator: (v) =>
                v != _newCtrl.text ? AppConfig.valPasswordMismatch : null,
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(AppConfig.profileSignOutCancel,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            AppConfig.profileDialogUpdate,
            style: GoogleFonts.dmSans(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Password field ────────────────────────────────────────────
class _PwdField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const _PwdField(
      {required this.controller, required this.label, this.validator});

  @override
  State<_PwdField> createState() => _PwdFieldState();
}

class _PwdFieldState extends State<_PwdField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      style:
          GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 12, color: AppColors.textSecondary),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        filled: true,
        fillColor: AppColors.background,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: widget.validator ??
          (v) {
            if (v == null || v.isEmpty) return AppConfig.valFieldRequired;
            if (v.length < 6) return AppConfig.valMinSixChars;
            return null;
          },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Profile Gamification Section
//  Inserted below _DonationStatCard — additive, no existing
//  profile content touched.
// ─────────────────────────────────────────────────────────────
class _ProfileGamificationSection extends ConsumerWidget {
  final int donationCount;
  const _ProfileGamificationSection({required this.donationCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamState = ref.watch(gamificationViewModelProvider);
    final data     = gamState.data;

    if (gamState.isLoading || data == null) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }

    final nextTier  = data.nextTier;
    final xpForNext = data.xpForNextTier;
    final progress  = xpForNext > 0
        ? (data.xp / xpForNext).clamp(0.0, 1.0)
        : 1.0;
    final earnedBadges = data.earnedBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── XP progress card ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(
                      data.tier.name,
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.urgentBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppConfig.profileGamDonor,
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ]),
                  Text(
                    '${data.xp} XP',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (nextTier != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(xpForNext - data.xp).clamp(0, xpForNext)} XP to ${nextTier.name}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Badges row ────────────────────────────────────────
        if (earnedBadges.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConfig.profileGamBadges,
                      style: GoogleFonts.syne(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.05,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/rewards'),
                      child: Text(
                        AppConfig.profileGamSeeAll,
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: earnedBadges.map((badge) {
                      final icon = _badgeIcon(badge.icon);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.urgentBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.urgentBorder),
                              ),
                              child: Icon(icon,
                                  size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badge.name,
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // ── Rank card ─────────────────────────────────────────
        GestureDetector(
          onTap: () => context.go('/rewards'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.urgentBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    data.cityRank > 0 ? '#${data.cityRank}' : '—',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.cityName.isNotEmpty
                          ? '${data.cityName} leaderboard'
                          : AppConfig.profileGamCityLb,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      AppConfig.profileGamThisMonth,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ]),
          ),
        ),
      ],
    );
  }

  IconData _badgeIcon(BadgeIcon icon) {
    switch (icon) {
      case BadgeIcon.heart:  return Icons.favorite_rounded;
      case BadgeIcon.bolt:   return Icons.bolt_rounded;
      case BadgeIcon.clock:  return Icons.access_time_rounded;
      case BadgeIcon.shield: return Icons.shield_rounded;
      case BadgeIcon.people: return Icons.people_rounded;
      case BadgeIcon.lock:   return Icons.lock_outline_rounded;
      case BadgeIcon.trophy: return Icons.emoji_events_rounded;
      default:               return Icons.star_rounded;
    }
  }
}
