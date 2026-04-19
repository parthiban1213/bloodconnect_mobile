import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
//  showRequestStatusModal
// ─────────────────────────────────────────────────────────────

void showRequestStatusModal(
  BuildContext context,
  BloodRequirement req, {
  bool isRequester = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: RequestStatusModal(requirement: req, isRequester: isRequester),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  RequestStatusModal
// ─────────────────────────────────────────────────────────────

class RequestStatusModal extends ConsumerStatefulWidget {
  final BloodRequirement requirement;
  final bool isRequester;

  const RequestStatusModal({
    super.key,
    required this.requirement,
    this.isRequester = false,
  });

  @override
  ConsumerState<RequestStatusModal> createState() => _RequestStatusModalState();
}

class _RequestStatusModalState extends ConsumerState<RequestStatusModal> {
  List<DonorPledge> _pledges     = [];
  bool              _loadingPledges = false;
  String?           _pledgesError;
  final Map<String, bool> _updating = {};
  // Tracks which pledge was just marked Completed for the Undo snackbar
  String? _lastCompletedUsername;

  @override
  void initState() {
    super.initState();
    if (widget.isRequester) _loadPledges();
  }

  Future<void> _loadPledges() async {
    setState(() { _loadingPledges = true; _pledgesError = null; });
    final pledges = await ref
        .read(myRequestsViewModelProvider.notifier)
        .fetchDonorPledges(widget.requirement.id);
    if (!mounted) return;
    setState(() { _pledges = pledges; _loadingPledges = false; });
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _markCompleted(DonorPledge pledge) async {
    setState(() => _updating[pledge.donorUsername] = true);

    final ok = await ref
        .read(requirementsViewModelProvider.notifier)
        .updateDonationStatus(
          requirementId: widget.requirement.id,
          donorUsername: pledge.donorUsername,
          newStatus: 'Completed',
        );

    if (!mounted) return;
    setState(() => _updating.remove(pledge.donorUsername));

    if (ok) {
      // Schedule eligibility reminder if current user was the donor
      final currentUser = ref.read(authViewModelProvider).user;
      if (currentUser?.username == pledge.donorUsername) {
        await ReminderService().scheduleEligibilityReminder(DateTime.now());
      }
      ref.read(historyViewModelProvider.notifier).load();
      ref.read(myRequestsViewModelProvider.notifier).load();
      await _loadPledges();

      // Show Undo snackbar — single-action recovery, no permanent revert UI
      if (mounted) {
        _lastCompletedUsername = pledge.donorUsername;
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
              label: 'Undo',
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

  Color get _statusColor {
    if (widget.requirement.isFulfilled) return const Color(0xFF1D9E75);
    if (widget.requirement.isCancelled) return AppColors.closedAccent;
    return AppColors.primary;
  }

  String get _statusLabel {
    if (widget.requirement.isFulfilled) return 'Fulfilled';
    if (widget.requirement.isCancelled) return 'Cancelled';
    return 'Open';
  }

  @override
  Widget build(BuildContext context) {
    // Watch live state so modal rebuilds immediately after mark completed
    // without needing to close and reopen.
    final myReqState = ref.watch(myRequestsViewModelProvider);
    final liveReq = myReqState.requests
        .where((r) => r.id == widget.requirement.id)
        .firstOrNull;
    final req      = liveReq ?? widget.requirement;
    final progress = req.fulfillmentProgress;

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
            // Title row
            Row(children: [
              Expanded(
                child: Text('Request Status',
                    style: GoogleFonts.syne(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // Header
            Row(children: [
              BloodTypeBadge(bloodType: req.bloodType, urgency: req.urgency),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.hospital,
                        style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    if (req.patientName.isNotEmpty)
                      Text(req.patientName,
                          style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary,
                          )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.4)),
                ),
                child: Text(_statusLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: _statusColor,
                    )),
              ),
            ]),

            const SizedBox(height: 24),

            // Progress
            Text('Donation Progress',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: AppColors.textMuted, letterSpacing: 0.5,
                )),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                color: req.isFulfilled
                    ? const Color(0xFF1D9E75)
                    : AppColors.primary,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${req.unitsFulfilled} of ${req.unitsRequired} units fulfilled',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
                Text('${(progress * 100).round()}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: req.isFulfilled
                          ? const Color(0xFF1D9E75)
                          : AppColors.primary,
                    )),
              ],
            ),

            // Pending count banner
            if (req.pendingCount > 0 && req.isOpen) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 13, color: Color(0xFF92400E)),
                  const SizedBox(width: 6),
                  Text(
                    '${req.pendingCount} donor${req.pendingCount != 1 ? 's' : ''} scheduled — awaiting your approval',
                    style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // Stats grid
            Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.people_outline_rounded,
                value: '${req.donationsCount}',
                label: AppConfig.modalDonorsLabel,
                color: AppColors.plannedAccent,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.bloodtype_outlined,
                value: '${req.remainingUnits}',
                label: AppConfig.modalUnitsRemainingLabel,
                color: req.remainingUnits == 0
                    ? const Color(0xFF1D9E75)
                    : AppColors.primary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                value: '${req.unitsFulfilled}',
                label: AppConfig.modalFulfilledLabel,
                color: const Color(0xFF1D9E75),
              )),
            ]),

            const SizedBox(height: 20),

            // Detail rows
            _DetailRow(label: AppConfig.modalUrgencyLabel,  value: req.urgency),
            _DetailRow(
              label: AppConfig.modalContactLabel,
              value: '${req.contactPerson} · ${req.contactPhone}',
            ),
            if (req.location.isNotEmpty)
              _DetailRow(label: AppConfig.modalLocationLabel, value: req.location),
            if (req.notes.isNotEmpty)
              _DetailRow(label: AppConfig.modalNotesLabel, value: req.notes),

            // Pledged donors section (requester only — no Available Donors tab)
            if (widget.isRequester) ...[
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 16),
              Text(
                AppConfig.donorListSectionTitle,
                style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              _buildDonorList(),
            ],

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorList() {
    if (_loadingPledges) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(AppConfig.donorListLoading,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
        ]),
      );
    }
    if (_pledgesError != null) {
      return Text(AppConfig.donorListError,
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.primary));
    }
    if (_pledges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(AppConfig.donorListEmpty,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
      );
    }
    return Column(
      children: _pledges
          .map((p) => _DonorPledgeCard(
                pledge:     p,
                isUpdating: _updating[p.donorUsername] == true,
                onMarkCompleted: p.isPending ? () => _markCompleted(p) : null,
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _DonorPledgeCard — Pending shows Mark Completed button,
//  Completed shows a green badge only (no revert toggle)
// ─────────────────────────────────────────────────────────────

class _DonorPledgeCard extends StatelessWidget {
  final DonorPledge pledge;
  final bool isUpdating;
  final VoidCallback? onMarkCompleted;

  const _DonorPledgeCard({
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
        ? pledge.donorName
        : pledge.donorUsername;
    final avatar = displayName[0].toUpperCase();

    String scheduleText = 'No schedule set';
    if (pledge.scheduledDate.isNotEmpty) {
      try {
        final d = DateTime.parse(pledge.scheduledDate);
        scheduleText = DateFormat('d MMM yyyy').format(d);
        if (pledge.scheduledTime.isNotEmpty) {
          scheduleText += '  🕐 ${pledge.scheduledTime}';
        }
      } catch (_) {
        scheduleText = pledge.scheduledDate;
        if (pledge.scheduledTime.isNotEmpty) scheduleText += '  ${pledge.scheduledTime}';
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
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.urgentBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(avatar,
              style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ))),
        ),
        const SizedBox(width: 10),

        // Name + schedule
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName,
                  style: GoogleFonts.syne(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              Text('@${pledge.donorUsername}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted,
                  )),
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
                  child: Text(scheduleText,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: pledge.scheduledDate.isNotEmpty
                            ? AppColors.plannedText
                            : AppColors.textMuted,
                        fontWeight: pledge.scheduledDate.isNotEmpty
                            ? FontWeight.w500
                            : FontWeight.w400,
                      )),
                ),
              ]),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Action: loading / Mark Completed button / Completed badge
        isUpdating
            ? const SizedBox(
                width: 22, height: 22,
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
                        border: Border.all(color: cardBorder, width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          AppConfig.donorMarkCompleted,
                          style: GoogleFonts.syne(
                            fontSize: 9, fontWeight: FontWeight.w700,
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
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: GoogleFonts.syne(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ]),
                  ),
      ]),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.icon, required this.value,
      required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.dmSans(
              fontSize: 20, fontWeight: FontWeight.w700, color: color,
            )),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 9, fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            )),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              )),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textPrimary,
              )),
        ),
      ]),
    );
  }
}
