import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/blood_requirement.dart';
import '../../viewmodels/my_requests_viewmodel.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../viewmodels/history_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/reminder_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/blood_type_badge.dart';

// ─────────────────────────────────────────────────────────────
//  showPledgedDonorsModal
// ─────────────────────────────────────────────────────────────

void showPledgedDonorsModal(
  BuildContext context,
  BloodRequirement req,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: PledgedDonorsModal(requirement: req),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  PledgedDonorsModal
// ─────────────────────────────────────────────────────────────

class PledgedDonorsModal extends ConsumerStatefulWidget {
  final BloodRequirement requirement;

  const PledgedDonorsModal({super.key, required this.requirement});

  @override
  ConsumerState<PledgedDonorsModal> createState() =>
      _PledgedDonorsModalState();
}

class _PledgedDonorsModalState extends ConsumerState<PledgedDonorsModal> {
  List<DonorPledge> _pledges = [];
  bool              _loading = true;
  String?           _error;
  final Map<String, bool> _updating = {};

  @override
  void initState() {
    super.initState();
    _loadPledges();
  }

  Future<void> _loadPledges() async {
    setState(() { _loading = true; _error = null; });
    final pledges = await ref
        .read(myRequestsViewModelProvider.notifier)
        .fetchDonorPledges(widget.requirement.id);
    if (!mounted) return;
    setState(() { _pledges = pledges; _loading = false; });
  }

  Future<void> _markCompleted(DonorPledge pledge) async {
    setState(() => _updating[pledge.donorUsername] = true);

    final ok = await ref
        .read(requirementsViewModelProvider.notifier)
        .updateDonationStatus(
          requirementId: widget.requirement.id,
          donorUsername: pledge.donorUsername,
          newStatus: AppConfig.pledgedDonorCompleted,
        );

    if (!mounted) return;
    setState(() => _updating.remove(pledge.donorUsername));

    if (ok) {
      final currentUser = ref.read(authViewModelProvider).user;
      if (currentUser?.username == pledge.donorUsername) {
        await ReminderService().scheduleEligibilityReminder(DateTime.now());
      }
      ref.read(historyViewModelProvider.notifier).load();
      ref.read(myRequestsViewModelProvider.notifier).load();
      await _loadPledges();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppConfig.donorCompletedSuccess,
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: AppConfig.pledgedUndoLabel,
              textColor: Colors.white,
              onPressed: () => _undoCompleted(pledge),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppConfig.donorStatusError,
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _undoCompleted(DonorPledge pledge) async {
    setState(() => _updating[pledge.donorUsername] = true);
    final ok = await ref
        .read(requirementsViewModelProvider.notifier)
        .updateDonationStatus(
          requirementId: widget.requirement.id,
          donorUsername: pledge.donorUsername,
          newStatus: 'Pending',
        );
    if (!mounted) return;
    setState(() => _updating.remove(pledge.donorUsername));
    if (ok) {
      ref.read(historyViewModelProvider.notifier).load();
      ref.read(myRequestsViewModelProvider.notifier).load();
      await _loadPledges();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch live state so the donor count badge in the header stays fresh
    final myReqState = ref.watch(myRequestsViewModelProvider);
    final liveReq = myReqState.requests
        .where((r) => r.id == widget.requirement.id)
        .firstOrNull;
    final req = liveReq ?? widget.requirement;

    final pendingCount   = _pledges.where((p) => p.isPending).length;
    final completedCount = _pledges.where((p) => p.isCompleted).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ─────────────────────────────────────
            Row(children: [
              Expanded(
                child: Text(
                  AppConfig.donorListSectionTitle,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Request mini-header ────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                BloodTypeBadge(
                    bloodType: req.bloodType, urgency: req.urgency),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.hospital,
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (req.patientName.isNotEmpty)
                        Text(
                          req.patientName,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Status pills ──────────────────────────────────
            if (!_loading && _pledges.isNotEmpty)
              Row(children: [
                _StatusPill(
                  count: pendingCount,
                  label: AppConfig.pledgedPendingLabel,
                  bg: const Color(0xFFFEF3C7),
                  tc: const Color(0xFF92400E),
                  border: const Color(0xFFFCD34D),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  count: completedCount,
                  label: AppConfig.pledgedCompletedLabel,
                  bg: const Color(0xFFDCFCE7),
                  tc: const Color(0xFF15803D),
                  border: const Color(0xFF86EFAC),
                ),
                const Spacer(),
                // Total badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.urgentBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_pledges.length} total',
                    style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ]),

            if (!_loading && _pledges.isNotEmpty) const SizedBox(height: 14),

            // ── Donor list ────────────────────────────────────
            _buildDonorList(),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorList() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              AppConfig.donorListLoading,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          AppConfig.donorListError,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.primary),
        ),
      );
    }

    if (_pledges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 36, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 10),
            Text(
              AppConfig.donorListEmpty,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Group: Pending first, then Completed
    final pending   = _pledges.where((p) => p.isPending).toList();
    final completed = _pledges.where((p) => p.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pending.isNotEmpty) ...[
          _GroupLabel(label: AppConfig.pledgedPendingApprovalGroup, color: const Color(0xFF92400E)),
          const SizedBox(height: 6),
          ...pending.map((p) => _DonorCard(
                pledge:     p,
                isUpdating: _updating[p.donorUsername] == true,
                onMarkCompleted: () => _markCompleted(p),
              )),
          if (completed.isNotEmpty) const SizedBox(height: 12),
        ],
        if (completed.isNotEmpty) ...[
          _GroupLabel(label: AppConfig.pledgedCompletedGroup, color: const Color(0xFF15803D)),
          const SizedBox(height: 6),
          ...completed.map((p) => _DonorCard(
                pledge:     p,
                isUpdating: _updating[p.donorUsername] == true,
                onMarkCompleted: null,
              )),
        ],
      ],
    );
  }
}

// ── Group label ───────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String label;
  final Color  color;
  const _GroupLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4, height: 4,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.syne(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    ]);
  }
}

// ── Status pill ───────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final int count;
  final String label;
  final Color bg, tc, border;
  const _StatusPill({
    required this.count,
    required this.label,
    required this.bg,
    required this.tc,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          '$count',
          style: GoogleFonts.syne(
              fontSize: 12, fontWeight: FontWeight.w700, color: tc),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.syne(
              fontSize: 10, fontWeight: FontWeight.w600, color: tc),
        ),
      ]),
    );
  }
}

// ── Donor card ────────────────────────────────────────────────

class _DonorCard extends StatelessWidget {
  final DonorPledge     pledge;
  final bool            isUpdating;
  final VoidCallback?   onMarkCompleted;

  const _DonorCard({
    required this.pledge,
    required this.isUpdating,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isPending   = pledge.isPending;
    final cardBorder  = isPending
        ? const Color(0xFFFCD34D)
        : const Color(0xFF86EFAC);
    final statusBg    = isPending
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFDCFCE7);
    final statusColor = isPending
        ? const Color(0xFF92400E)
        : const Color(0xFF15803D);

    final displayName = pledge.donorName.isNotEmpty
        ? pledge.donorName.split(' ').first
        : pledge.donorUsername;
    final avatar = displayName[0].toUpperCase();

    String scheduleText = AppConfig.donorNoScheduleSet;
    if (pledge.scheduledDate.isNotEmpty) {
      try {
        final d = DateTime.parse(pledge.scheduledDate);
        scheduleText = DateFormat('d MMM yyyy').format(d);
        if (pledge.scheduledTime.isNotEmpty) {
          scheduleText += '  🕐 ${pledge.scheduledTime}';
        }
      } catch (_) {
        scheduleText = pledge.scheduledDate;
        if (pledge.scheduledTime.isNotEmpty) {
          scheduleText += '  ${pledge.scheduledTime}';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.urgentBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              avatar,
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name + schedule
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: GoogleFonts.syne(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Row(children: [
                Icon(
                  pledge.scheduledDate.isNotEmpty
                      ? Icons.calendar_today_rounded
                      : Icons.calendar_today_outlined,
                  size: 11,
                  color: pledge.scheduledDate.isNotEmpty
                      ? AppColors.plannedAccent
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    scheduleText,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: pledge.scheduledDate.isNotEmpty
                          ? AppColors.plannedText
                          : AppColors.textMuted,
                      fontWeight: pledge.scheduledDate.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Action
        isUpdating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.primary),
              )
            : isPending
                ? GestureDetector(
                    onTap: onMarkCompleted,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: cardBorder, width: 1.5),
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              AppConfig.donorMarkCompleted,
                              style: GoogleFonts.syne(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ]),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder, width: 1.5),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            AppConfig.pledgedDonorCompleted,
                            style: GoogleFonts.syne(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ]),
                  ),
      ]),
    );
  }
}
