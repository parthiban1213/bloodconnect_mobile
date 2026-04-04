import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/prefs_service.dart';

/// Shows a one-time dialog prompting the user to set a password after
/// registering via OTP (which creates an account without a password).
///
/// Displays only once — as soon as the user taps either button the flag is
/// cleared and the dialog will never appear again.
class PasswordPromptDialog extends StatelessWidget {
  const PasswordPromptDialog({super.key});

  /// Convenience helper — checks the flag and, if set, shows the dialog.
  /// Safe to call from initState via addPostFrameCallback.
  static Future<void> showIfNeeded(BuildContext context) async {
    final should = await PrefsService.shouldShowPasswordPrompt();
    if (!should) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // force an explicit choice
      builder: (_) => const PasswordPromptDialog(),
    );
  }

  Future<void> _dismiss(BuildContext context, {required bool goToProfile}) async {
    await PrefsService.clearPasswordPrompt();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (goToProfile) {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header band ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Secure Your Account',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'You registered using a one-time code. '
                'We recommend setting a password so you can also '
                'sign in with your username.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ),

            // ── Actions ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  // Primary — go to profile / security
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _dismiss(context, goToProfile: true),
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text(
                        'Update Password',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Secondary — skip
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _dismiss(context, goToProfile: false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                        ),
                      ),
                      child: Text(
                        'Skip for Now',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
