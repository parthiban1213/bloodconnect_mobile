import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/reminder_service.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  EligibilityCard
//  Shown on the Profile screen below the availability toggle.
//  Displays:
//   • If eligible        → green "Ready to donate" banner
//   • If in cooldown     → progress bar + days remaining
//                        + "Remind me" toggle
// ─────────────────────────────────────────────────────────────

class EligibilityCard extends StatefulWidget {
  final DateTime? lastDonationDate;

  const EligibilityCard({super.key, required this.lastDonationDate});

  @override
  State<EligibilityCard> createState() => _EligibilityCardState();
}

class _EligibilityCardState extends State<EligibilityCard> {
  bool _reminderOn = false;
  static const _storage = FlutterSecureStorage();
  static const _reminderKey = 'eligibility_reminder_on';

  @override
  void initState() {
    super.initState();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final val = await _storage.read(key: _reminderKey);
    if (mounted) setState(() => _reminderOn = val == 'true');
  }

  Future<void> _saveReminderState(bool val) async {
    await _storage.write(key: _reminderKey, value: val.toString());
  }

  @override
  Widget build(BuildContext context) {
    final eligible  = ReminderService.isEligible(widget.lastDonationDate);
    final progress  = ReminderService.eligibilityProgress(widget.lastDonationDate);
    final daysLeft  = ReminderService.daysUntilEligible(widget.lastDonationDate);
    final nextDate  = ReminderService.nextEligibleDate(widget.lastDonationDate);

    if (eligible) {
      return _EligibleBanner();
    }

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
          // ── Header ─────────────────────────────────────────
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.moderateBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.hourglass_top_rounded,
                    size: 16, color: AppColors.moderateAccent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Donation eligibility',
                    style: GoogleFonts.syne(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
                  Text(
                    nextDate != null
                        ? 'Eligible on ${DateFormat('d MMM yyyy').format(nextDate)}'
                        : 'Calculating…',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            // Days pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.moderateBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$daysLeft days',
                style: GoogleFonts.syne(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.moderateAccent),
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Progress bar ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textVeryMuted)),
              Text('56 days',
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textVeryMuted)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.85
                    ? AppColors.secondary
                    : AppColors.moderateAccent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).round()}% of cooldown complete',
            style: GoogleFonts.dmSans(
                fontSize: 10, color: AppColors.textMuted),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 12),

          // ── Reminder toggle ─────────────────────────────────
          Row(children: [
            const Icon(Icons.notifications_none_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _reminderOn
                    ? 'Reminder set for ${daysLeft > 3 ? DateFormat('d MMM').format(nextDate!.subtract(const Duration(days: 3))) : 'soon'}'
                    : 'Remind me when I\'m eligible',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final newVal = !_reminderOn;
                setState(() => _reminderOn = newVal);
                await _saveReminderState(newVal);
                if (newVal) {
                  await ReminderService()
                      .scheduleEligibilityReminder(widget.lastDonationDate);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        'Reminder set! We\'ll notify you 3 days before you\'re eligible.',
                        style: GoogleFonts.dmSans(fontSize: 13)),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                } else {
                  await ReminderService().cancelEligibilityReminder();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _reminderOn
                      ? AppColors.secondary.withOpacity(0.15)
                      : AppColors.closedBg,
                  border: Border.all(
                    color: _reminderOn
                        ? AppColors.secondary
                        : AppColors.closedBorder,
                    width: 1.5,
                  ),
                ),
                child: Stack(children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _reminderOn
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _reminderOn
                            ? AppColors.secondary
                            : AppColors.closedAccent,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _EligibleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9FE1CB)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Center(
            child: Icon(Icons.volunteer_activism_rounded,
                size: 18, color: AppColors.secondary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ready to donate!',
                style: GoogleFonts.syne(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: const Color(0xFF085041))),
              Text('You are currently eligible to donate blood.',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: const Color(0xFF0F6E56))),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded,
            size: 20, color: AppColors.secondary),
      ]),
    );
  }
}
