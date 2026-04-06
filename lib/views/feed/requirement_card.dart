import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/blood_requirement.dart';
import '../../utils/app_extensions.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/reminder_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/blood_type_badge.dart';
import '../../widgets/schedule_pledge_modal.dart';

class RequirementCard extends ConsumerWidget {
  final BloodRequirement requirement;

  const RequirementCard({super.key, required this.requirement});

  bool get _isClosed =>
      requirement.status == 'Fulfilled' || requirement.status == 'Cancelled';

  Future<void> _handleDonate(BuildContext context, WidgetRef ref) async {
    // Step 1: ask for scheduled date + time
    final schedule = await showSchedulePledgeModal(
      context,
      patientName: requirement.patientName,
      bloodType:   requirement.bloodType,
    );
    if (schedule == null) return; // user cancelled
    if (!context.mounted) return;

    final vm      = ref.read(requirementsViewModelProvider.notifier);
    final updated = await vm.donate(
      requirement.id,
      scheduledDate: schedule.scheduledDate,
      scheduledTime: schedule.scheduledTime,
    );

    if (!context.mounted) return;

    if (updated == null) {
      final err = ref.read(requirementsViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          err ?? AppConfig.commonErrorRetry,
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    // NOTE: ReminderService.scheduleEligibilityReminder is NOT called here.
    // The 90-day cooldown only starts when the requester marks the donation
    // as Completed. The reminder is triggered from the status modal at that point.

    if (context.mounted) {
      context.push('/accepted', extra: {
        'hospital':      requirement.hospital,
        'contactPerson': requirement.contactPerson,
        'contactPhone':  requirement.contactPhone,
        'location':      requirement.location,
        'bloodType':     requirement.bloodType,
      });
    }
  }


  Future<void> _shareRequirement(BuildContext context) async {
    final text = AppConfig.shareText(
      bloodType: requirement.bloodType,
      hospital:  requirement.hospital,
      location:  requirement.location,
      urgency:   requirement.urgency,
      units:     '${requirement.remainingUnits}',
      contactPhone: requirement.contactPhone,
    );
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state           = ref.watch(requirementsViewModelProvider);
    final authState       = ref.watch(authViewModelProvider);
    final isDonating      = state.isDonating(requirement.id);
    final hasDonated      = state.hasDonated(requirement.id);
    final canDonate       = state.userBloodType.isNotEmpty &&
                            state.userBloodType == requirement.bloodType;
    // Eligibility: user is ineligible if within 90-day cooldown after donation
    final lastDonation    = authState.user?.lastDonationDate;
    final isInCooldown    = !ReminderService.isEligible(lastDonation);
    // Unavailable donors cannot pledge
    final isUnavailable   = authState.user?.isAvailable == false;
    // Fix #1: show "Already Donated" when user already donated to this multi-unit request
    final showAlreadyDonated = hasDonated && !_isClosed;
    // Check if this specific pledge is pending (scheduled but not yet approved)
    final myPledge = requirement.donorPledges
        .where((p) => p.donorUsername == (authState.user?.username ?? ''))
        .firstOrNull;
    final isScheduledPending = myPledge != null && myPledge.isPending;

    return Opacity(
      opacity: _isClosed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: _isClosed
            ? null
            : () => context.push(
                  '/requirement/${requirement.id}',
                  extra: {'requirement': requirement},
                ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BloodTypeBadge(
                    bloodType: requirement.bloodType,
                    urgency: requirement.urgency,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requirement.hospital,
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Fix #8: display location
                        if (requirement.location.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 11, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  requirement.location.toUpperCase(),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11, color: AppColors.primary,fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          '${requirement.remainingUnits} unit${requirement.remainingUnits != 1 ? 's' : ''} still needed',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppColors.primary),
                        ),
                        if (requirement.patientName.isNotEmpty)
                          Text(
                            requirement.patientName,
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          requirement.createdAt.timeAgo,
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Share icon
                  if (!_isClosed)
                    GestureDetector(
                      onTap: () => _shareRequirement(context),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.urgentBorder),
                        ),
                        child: const Icon(Icons.share_rounded,
                            size: 13, color: AppColors.primary),
                      ),
                    ),
                ],
              ),

              if (!_isClosed) ...[
                const SizedBox(height: 12),
                _ProgressRow(requirement: requirement),

                const SizedBox(height: 12),

                // Fix #1: Already Donated (Completed) badge
                if (showAlreadyDonated && !isScheduledPending)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF9FE1CB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: Color(0xFF085041)),
                        const SizedBox(width: 6),
                        Text(
                          AppConfig.cardAlreadyDonated,
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF085041),
                          ),
                        ),
                      ],
                    ),
                  )
                // Scheduled / awaiting approval badge
                else if (isScheduledPending)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            size: 14, color: Color(0xFF92400E)),
                        const SizedBox(width: 6),
                        Text(
                          '⏳ Scheduled — awaiting approval',
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  )
                // "Not Eligible" only when blood type matches but user is in cooldown
                else if (canDonate && isInCooldown)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.moderateBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.moderateBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.block_rounded,
                            size: 14, color: AppColors.moderateAccent),
                        const SizedBox(width: 6),
                        Text(
                          AppConfig.cardNotEligibleBtn,
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.moderateAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                // Unavailable donor — matching type only
                else if (canDonate && isUnavailable)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.closedBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.closedBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.do_not_disturb_rounded,
                            size: 14, color: AppColors.closedAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Update availability in Profile',
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.closedText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(children: [
                    if (canDonate) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: isDonating
                              ? null
                              : () => _handleDonate(context, ref),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isDonating
                                  ? AppColors.primary.withOpacity(0.55)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: isDonating
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      AppConfig.cardDonateBtn,
                                      style: GoogleFonts.syne(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onTap: canDonate
                            ? () {
                                ref
                                    .read(requirementsViewModelProvider.notifier)
                                    .declineDonation(requirement.id);
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: canDonate
                                ? AppColors.background
                                : AppColors.border.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: canDonate
                                  ? AppColors.border
                                  : AppColors.border.withOpacity(0.5),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              canDonate ? AppConfig.cardCantHelpBtn : "Not my type",
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: canDonate
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  requirement.status == 'Fulfilled'
                      ? 'Fulfilled — ${requirement.donorCount} donor${requirement.donorCount != 1 ? 's' : ''} responded'
                      : 'Cancelled',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final BloodRequirement requirement;
  const _ProgressRow({required this.requirement});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${requirement.unitsFulfilled}/${requirement.unitsRequired} pledged',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${requirement.remainingUnits} remaining',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: requirement.fulfillmentProgress,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
