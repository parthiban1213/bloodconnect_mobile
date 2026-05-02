import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_update_service.dart';
import '../utils/app_config.dart';
import '../utils/app_theme.dart';

/// A bottom-sheet-style dialog shown when a new app version is available.
///
/// Usage (from initState via addPostFrameCallback):
/// ```dart
///   final info = await AppUpdateService.checkForUpdate();
///   if (info.hasUpdate && mounted) {
///     await AppUpdateDialog.show(context, info);
///   }
/// ```
class AppUpdateDialog extends StatelessWidget {
  final UpdateInfo info;

  const AppUpdateDialog({super.key, required this.info});

  // ── Store URLs ─────────────────────────────────────────────────────────────
  // Replace these with your actual Play Store / App Store listing URLs.
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.hsblood.bloodconnect';
  static const _appStoreUrl =
      'https://apps.apple.com/app/bloodconnect/id000000000';

  static const _snoozeKey      = 'update_snoozed_until';
  static const _snoozeDuration = Duration(hours: 24);

  /// Shows the update dialog. When [info.isForced] is true the dialog is
  /// not dismissible — the user must tap "Update Now".
  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.isForced,
      builder: (_) => AppUpdateDialog(info: info),
    );
  }

  /// Returns true if the user tapped "Remind Me Later" within the last 24h.
  /// Force updates are never snoozed.
  static Future<bool> _isSnoozed(bool isForced) async {
    if (isForced) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snoozedMs = prefs.getInt(_snoozeKey);
      if (snoozedMs == null) return false;
      final snoozedUntil = DateTime.fromMillisecondsSinceEpoch(snoozedMs);
      return DateTime.now().isBefore(snoozedUntil);
    } catch (_) {
      return false;
    }
  }

  /// Saves a 24-hour snooze timestamp to shared preferences.
  static Future<void> _snooze() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snoozedUntil = DateTime.now().add(_snoozeDuration);
      await prefs.setInt(_snoozeKey, snoozedUntil.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Checks Remote Config and shows the dialog if an update is available
  /// and the user has not snoozed it within the last 24 hours.
  /// Force updates always show regardless of snooze.
  /// Safe to call from initState via addPostFrameCallback.
  static Future<void> showIfNeeded(BuildContext context) async {
    final info = await AppUpdateService.checkForUpdate();
    if (!info.hasUpdate) return;
    if (await _isSnoozed(info.isForced)) return;
    if (!context.mounted) return;
    await AppUpdateDialog.show(context, info);
  }

  Future<void> _openStore() async {
    // Try Play Store first; fall back to App Store.
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final iosUri = Uri.parse(_appStoreUrl);
      if (await canLaunchUrl(iosUri)) {
        await launchUrl(iosUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  List<String> get _bullets {
    final notes = info.releaseNotes.trim();
    if (notes.isEmpty) {
      return AppConfig.updateDefaultBullets;
    }
    return notes.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back button dismissal when update is forced.
      canPop: !info.isForced,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: _DialogContent(
          info: info,
          bullets: _bullets,
          onUpdate: _openStore,
          onLater: info.isForced
              ? null
              : () {
                  AppUpdateDialog._snooze();
                  Navigator.of(context).pop();
                },
        ),
      ),
    );
  }
}

// ── Private widget — keeps the build method clean ─────────────────────────────

class _DialogContent extends StatelessWidget {
  final UpdateInfo info;
  final List<String> bullets;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const _DialogContent({
    required this.info,
    required this.bullets,
    required this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Red header ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                // Blood-drop icon with version badge
                _BloodDropIcon(label: 'NEW'),
                const SizedBox(height: 12),
                Text(
                  info.isForced ? AppConfig.updateForceTitle : AppConfig.updateOptionalTitle,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.isForced
                      ? 'Version ${info.latestVersion} is required to continue'
                      : 'Version ${info.latestVersion} is ready',
                  style: GoogleFonts.syne(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.06,
                  ),
                ),
              ],
            ),
          ),

          // ── White body ───────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  info.isForced
                      ? AppConfig.updateForceDesc
                      : AppConfig.updateOptionalDesc,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),

                // What's new section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConfig.updateWhatsNewLabel,
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...bullets.map((b) => _Bullet(text: b)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppConfig.updateNowBtn,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.04,
                      ),
                    ),
                  ),
                ),

                if (onLater != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onLater,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        AppConfig.updateLaterBtn,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Center(
                  child: Text(
                    info.isForced
                        ? AppConfig.updateForceFooter
                        : AppConfig.updateOptionalFooter,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodDropIcon extends StatelessWidget {
  final String label;
  const _BloodDropIcon({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: CustomPaint(painter: _DropPainter(label: label)),
    );
  }
}

class _DropPainter extends CustomPainter {
  final String label;
  const _DropPainter({required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size.width / 2;
    // Drop shape: pointed top, rounded bottom
    path.moveTo(cx, 0);
    path.cubicTo(cx + 20, size.height * 0.35, size.width, size.height * 0.55,
        size.width, size.height * 0.72);
    path.arcToPoint(
      Offset(0, size.height * 0.72),
      radius: Radius.circular(size.width / 2),
      largeArc: true,
    );
    path.cubicTo(0, size.height * 0.55, cx - 20, size.height * 0.35, cx, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Label text inside drop
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.04,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, size.height * 0.52 - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_DropPainter old) => old.label != label;
}
