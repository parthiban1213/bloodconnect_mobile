import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_extensions.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh profile every time this screen is shown so data is always current
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authViewModelProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authVm    = ref.read(authViewModelProvider.notifier);
    final user      = authState.user;

    // Show shimmer while profile is loading for the first time (no user data yet)
    if (user == null && authState.isLoading) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/feed');
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
              children: List.generate(5, (_) => const CardShimmer()),
            ),
          ),
        ),
      );
    }

    // Fix #5: back button on profile screen navigates to feed, not app exit
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/feed');
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          onRefresh: () => authVm.refreshProfile(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
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

              // ── Availability toggle (fixed) ──────────────
              _AvailabilityCard(
                isAvailable: user?.isAvailable ?? false,
                onToggle: (val) => authVm.updateAvailability(val),
              ),
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
                    showDivider: true,
                  ),
                  _MenuItem(
                    icon: user?.isAdmin == true
                        ? Icons.admin_panel_settings_outlined
                        : Icons.info_outline_rounded,
                    iconBg: AppColors.moderateBg,
                    iconColor: AppColors.moderateText,
                    label: AppConfig.profileAccountRole,
                    value: user?.role.isNotEmpty == true
                        ? user!.role[0].toUpperCase() + user.role.substring(1)
                        : 'User',
                    onTap: null,
                    showDivider: false,
                  ),
                ]),
              ),

              if (user?.lastDonationDate != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.favorite_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      AppConfig.profileLastDonation,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      user!.lastDonationDate!.formatted,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ]),
                ),
              ],

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
            ],
          ),
        ),
      ),
      ), // closes PopScope (fix #5)
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out',
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

  Future<void> _showChangePasswordDialog(
      BuildContext context, WidgetRef ref) async {
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password',
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _PwdField(controller: newCtrl, label: 'New password'),
            const SizedBox(height: 10),
            _PwdField(
              controller: confirmCtrl,
              label: 'Confirm new password',
              validator: (v) =>
                  v != newCtrl.text ? 'Passwords do not match' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppConfig.profileSignOutCancel,
                style:
                    GoogleFonts.dmSans(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await ref
                  .read(authViewModelProvider.notifier)
                  .changePassword('', newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(
                    ok
                        ? AppConfig.profilePwdChanged
                        : AppConfig.profilePwdChangeFailed,
                  ),
                  backgroundColor:
                      ok ? AppColors.secondary : AppColors.primary,
                ));
              }
            },
            child: Text('Update',
                style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600))),
        ],
      ),
    );
    newCtrl.dispose();
    confirmCtrl.dispose();
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

// ── Availability toggle — fixed UI ───────────────────────────
// Uses a custom toggle instead of Flutter's Switch to avoid the
// "fully filled" look that confuses users. Shows a clear
// ON/OFF label next to an outlined pill toggle.
class _AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onToggle;

  const _AvailabilityCard({
    required this.isAvailable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        // Status dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isAvailable ? AppColors.secondary : AppColors.closedAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.profileAvailableLabel,
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAvailable
                    ? AppConfig.profileAvailableOn
                    : AppConfig.profileAvailableOff,
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        // Custom pill toggle — clear ON/OFF, not a filled block
        GestureDetector(
          onTap: () => onToggle(!isAvailable),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isAvailable
                  ? AppColors.secondary.withOpacity(0.12)
                  : AppColors.closedBg,
              border: Border.all(
                color: isAvailable
                    ? AppColors.secondary
                    : AppColors.closedBorder,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isAvailable
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable
                          ? AppColors.secondary
                          : AppColors.closedAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
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
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          },
    );
  }
}
