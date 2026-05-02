import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/blood_requirement.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../utils/app_extensions.dart';
import '../../services/reminder_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/blood_type_badge.dart';
import '../../widgets/urgency_bar.dart';
import '../../widgets/schedule_pledge_modal.dart';

class RequirementDetailScreen extends ConsumerStatefulWidget {
  final String requirementId;
  final BloodRequirement? requirement;

  const RequirementDetailScreen({
    super.key,
    required this.requirementId,
    this.requirement,
  });

  @override
  ConsumerState<RequirementDetailScreen> createState() =>
      _RequirementDetailScreenState();
}

class _RequirementDetailScreenState
    extends ConsumerState<RequirementDetailScreen> {
  BloodRequirement? _requirement;
  bool _isLoading = false;
  bool _isConfirming = false;
  bool _isCancellingPledge = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requirement = widget.requirement;
    if (_requirement == null) _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final detail = await ref
        .read(requirementsViewModelProvider.notifier)
        .getDetail(widget.requirementId);
    setState(() {
      _requirement = detail;
      _isLoading = false;
      if (detail == null) _error = 'Could not load request details.';
    });
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDonation() async {
    if (_requirement == null) return;

    // Show schedule modal first — require date + time before pledging
    final schedule = await showSchedulePledgeModal(
      context,
      patientName: _requirement!.patientName,
      bloodType:   _requirement!.bloodType,
    );
    if (schedule == null) return; // user cancelled
    if (!mounted) return;

    setState(() => _isConfirming = true);
    final updated = await ref
        .read(requirementsViewModelProvider.notifier)
        .donate(
      _requirement!.id,
      scheduledDate: schedule.scheduledDate,
      scheduledTime: schedule.scheduledTime,
    );
    setState(() => _isConfirming = false);
    if (updated != null && mounted) {
      // NOTE: ReminderService is NOT called here — the 90-day cooldown
      // only begins when the requester marks the donation Completed.
      context.pushReplacement('/accepted', extra: {
        'hospital':      _requirement!.hospital,
        'contactPerson': _requirement!.contactPerson,
        'contactPhone':  _requirement!.contactPhone,
        'location':      _requirement!.location,
        'bloodType':     _requirement!.bloodType,
      });
    } else if (mounted) {
      final err = ref.read(requirementsViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? AppConfig.commonFailedConfirm),
        backgroundColor: AppColors.primary,
      ));
    }
  }

  Future<void> _cancelPledge() async {
    if (_requirement == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppConfig.detailCancelPledgeConfirmTitle,
          style: GoogleFonts.syne(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Text(
          AppConfig.detailCancelPledgeConfirmBody,
          style: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppConfig.reqKeepPledge,
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppConfig.detailCancelPledgeBtn,
              style: GoogleFonts.dmSans(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancellingPledge = true);
    final ok = await ref
        .read(requirementsViewModelProvider.notifier)
        .cancelPledge(_requirement!.id);
    if (!mounted) return;
    setState(() => _isCancellingPledge = false);

    if (ok) {
      // Re-fetch detail so the action bar reverts to the donate state
      await _fetchDetail();
    } else {
      final err = ref.read(requirementsViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? AppConfig.reqCancelPledgeFailed),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const AppLoader()
                  : _error != null
                  ? ErrorView(
                message: _error!,
                onRetry: _fetchDetail,
              )
                  : _requirement == null
                  ? const ErrorView(message: AppConfig.detailNotFound)
                  : _buildContent(),
            ),
            if (_requirement != null && _requirement!.isOpen)
              _buildActionBar(),
          ],
        ),
      ),
    );
  }


  Future<void> _shareRequirement(BloodRequirement req) async {
    final text = AppConfig.shareText(
      bloodType: req.bloodType,
      hospital:  req.hospital,
      location:  req.location,
      urgency:   req.urgency,
      units:     '${req.remainingUnits}',
      contactPhone: req.contactPhone,
    );
    await Share.share(text);
  }

  Widget _buildContent() {
    final req = _requirement!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + Share row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left_rounded,
                              size: 18, color: AppColors.primary),
                          Text(
                            AppConfig.cardBackToFeed,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _shareRequirement(req),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.plannedBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.plannedBorder),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.share_rounded,
                              size: 13, color: AppColors.plannedText),
                          const SizedBox(width: 5),
                          Text(AppConfig.shareBtn,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  color: AppColors.plannedText)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Hero card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          BloodTypeBadge(
                            bloodType: req.bloodType,
                            urgency: req.urgency,
                            size: 60,
                            large: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.hospital,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (req.location.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 12, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          req.location.toUpperCase(),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.urgentBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        req.urgency == 'Critical'
                                            ? 'Urgent · ${UrgencyHelper.timeRemaining(req.requiredBy)}'
                                            : '${req.urgency} · ${UrgencyHelper.timeRemaining(req.requiredBy)}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.urgentText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Info grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _InfoTile(
                      label: AppConfig.detailUnitsNeeded,
                      value:
                      '${req.unitsRequired} unit${req.unitsRequired > 1 ? 's' : ''}'),
                  _InfoTile(
                      label: AppConfig.detailPatient,
                      value: req.patientName.isNotEmpty
                          ? req.patientName
                          : AppConfig.detailNotSpecified),
                  _InfoTile(label: AppConfig.detailUrgency, value: req.urgency,
                      valueColor: req.urgency == 'Critical'
                          ? AppColors.primary
                          : null),
                  _InfoTile(
                      label: AppConfig.detailStatus,
                      value: req.status,
                      valueColor: req.isOpen
                          ? AppColors.secondary
                          : AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 14),
              // Contact card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: const Border.fromBorderSide(
                      BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.detailHospitalContact,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.contactPerson,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                req.contactPhone,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.linkColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _callPhone(req.contactPhone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.plannedBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.call_rounded,
                                    size: 13,
                                    color: AppColors.plannedText),
                                const SizedBox(width: 6),
                                Text(
                                  AppConfig.commonCallBtn,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.plannedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (req.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.moderateBg,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.moderateBorder)),
                  ),
                  child: Text(
                    req.notes,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.moderateText,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
              if (req.requiredBy != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        AppConfig.detailRequiredBy,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        req.requiredBy!.formattedWithTime,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Posted ${req.createdAt.timeAgo}',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.textVeryMuted,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    final vmState    = ref.read(requirementsViewModelProvider);
    final authState  = ref.read(authViewModelProvider);
    final userBt     = vmState.userBloodType;
    final canDonate  = userBt.isNotEmpty && userBt == _requirement?.bloodType;
    // Derive hasDonated from two sources:
    //  1. The viewmodel's donatedIds set (populated from server on every feed load)
    //  2. The requirement's own donorUsernames (from the individually fetched detail)
    // Using both ensures correctness even if only one source is available.
    final username   = authState.user?.username ?? '';
    final hasDonated = vmState.hasDonated(_requirement?.id ?? '') ||
        (_requirement?.hasDonatedBy(username) ?? false);

    // Eligibility: user is ineligible if within 90-day cooldown after donation
    final lastDonation = authState.user?.lastDonationDate;
    final isInCooldown = !ReminderService.isEligible(lastDonation);

    // Check whether the user's pledge is Pending (awaiting approval) or Completed
    final myPledge = _requirement?.donorPledges
        .where((p) => p.donorUsername == username)
        .firstOrNull;
    final isScheduledPending = myPledge != null && myPledge.isPending;
    // Only show green "Already Donated" badge when pledge is actually Completed
    final isDonationCompleted = myPledge != null && myPledge.isCompleted;

    // Show "⏳ Scheduled — awaiting approval" + Cancel Pledge button
    if (hasDonated && isScheduledPending) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Pending status indicator
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 15, color: Color(0xFF92400E)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppConfig.detailScheduledPending,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Cancel pledge button (icon only)
              GestureDetector(
                onTap: _isCancellingPledge
                    ? null
                    : () => _cancelPledge(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.closedBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.closedBorder),
                  ),
                  child: Center(
                    child: _isCancellingPledge
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.closedText),
                    )
                        : const Icon(Icons.cancel_outlined,
                        size: 18, color: AppColors.closedText),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show green "✅ Already Donated" only when pledge is Completed (requester approved)
    if (isDonationCompleted || (hasDonated && !isScheduledPending)) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9FE1CB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 16, color: Color(0xFF085041)),
                const SizedBox(width: 8),
                Text(
                  AppConfig.detailAlreadyDonated,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF085041),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show "Not Eligible" banner only when blood type matches but user is in cooldown
    if (canDonate && isInCooldown) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.moderateBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.moderateBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block_rounded,
                    size: 16, color: AppColors.moderateAccent),
                const SizedBox(width: 8),
                Text(
                  AppConfig.cardNotEligibleBtn,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.moderateAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (canDonate) ...[
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _isConfirming ? null : _confirmDonation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isConfirming
                          ? AppColors.primary.withOpacity(0.55)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isConfirming
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : Text(
                        AppConfig.cardConfirmDonation,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (!canDonate)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.fromBorderSide(BorderSide(
                      color: AppColors.border.withOpacity(0.5),
                    )),
                  ),
                  child: Center(
                    child: Text(
                      AppConfig.cardNotMyTypeBtn,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
        const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}