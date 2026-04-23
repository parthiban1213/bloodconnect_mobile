import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/blood_requirement.dart';
import '../../viewmodels/my_requests_viewmodel.dart';
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
      child: RequestStatusModal(requirement: req),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  RequestStatusModal
// ─────────────────────────────────────────────────────────────

class RequestStatusModal extends ConsumerWidget {
  final BloodRequirement requirement;

  const RequestStatusModal({super.key, required this.requirement});

  Color _statusColor(BloodRequirement req) {
    if (req.isFulfilled) return const Color(0xFF1D9E75);
    if (req.isCancelled) return AppColors.closedAccent;
    return AppColors.primary;
  }

  String _statusLabel(BloodRequirement req) {
    if (req.isFulfilled) return 'Fulfilled';
    if (req.isCancelled) return 'Cancelled';
    return 'Open';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReqState = ref.watch(myRequestsViewModelProvider);
    final liveReq    = myReqState.requests
        .where((r) => r.id == requirement.id)
        .firstOrNull;
    final req      = liveReq ?? requirement;
    final progress = req.fulfillmentProgress;
    final sc       = _statusColor(req);

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

            // ── Header ────────────────────────────────────────
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
                  color: sc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withOpacity(0.4)),
                ),
                child: Text(_statusLabel(req),
                    style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: sc,
                    )),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Progress ──────────────────────────────────────
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

            // ── Pending count banner ──────────────────────────
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
                  Expanded(
                    child: Text(
                      '${req.pendingCount} donor${req.pendingCount != 1 ? 's' : ''} scheduled — awaiting your approval',
                      style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // ── Stats grid ────────────────────────────────────
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

            // ── Detail rows ───────────────────────────────────
            _DetailRow(label: AppConfig.modalUrgencyLabel, value: req.urgency),
            _DetailRow(
              label: AppConfig.modalContactLabel,
              value: '${req.contactPerson} · ${req.contactPhone}',
            ),
            if (req.location.isNotEmpty)
              _DetailRow(label: AppConfig.modalLocationLabel, value: req.location),
            if (req.notes.isNotEmpty)
              _DetailRow(label: AppConfig.modalNotesLabel, value: req.notes),

            const SizedBox(height: 4),
          ],
        ),
      ),
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