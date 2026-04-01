import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/blood_requirement.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/blood_type_badge.dart';

// ─────────────────────────────────────────────────────────────
//  RequestStatusModal
//  Bottom-sheet popup opened from My Requests screen.
//  Shows: donors received, units remaining, fulfillment progress.
// ─────────────────────────────────────────────────────────────

void showRequestStatusModal(BuildContext context, BloodRequirement req) {
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

class RequestStatusModal extends StatelessWidget {
  final BloodRequirement requirement;
  const RequestStatusModal({super.key, required this.requirement});

  Color get _statusColor {
    if (requirement.isFulfilled) return const Color(0xFF1D9E75);
    if (requirement.isCancelled) return AppColors.closedAccent;
    return AppColors.primary;
  }

  String get _statusLabel {
    if (requirement.isFulfilled) return 'Fulfilled';
    if (requirement.isCancelled) return 'Cancelled';
    return 'Open';
  }

  @override
  Widget build(BuildContext context) {
    final progress = requirement.fulfillmentProgress;

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
            // Dialog title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request Status',
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
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

          // ── Header ────────────────────────────────────────
          Row(
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
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (requirement.patientName.isNotEmpty)
                      Text(
                        requirement.patientName,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Progress section ──────────────────────────────
          Text(
            'Donation Progress',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              color: requirement.isFulfilled
                  ? const Color(0xFF1D9E75)
                  : AppColors.primary,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${requirement.unitsFulfilled} of ${requirement.unitsRequired} units fulfilled',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: requirement.isFulfilled
                      ? const Color(0xFF1D9E75)
                      : AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Stats grid ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_outline_rounded,
                  value: '${requirement.donorCount}',
                  label: AppConfig.modalDonorsLabel,
                  color: AppColors.plannedAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.bloodtype_outlined,
                  value: '${requirement.remainingUnits}',
                  label: AppConfig.modalUnitsRemainingLabel,
                  color: requirement.remainingUnits == 0
                      ? const Color(0xFF1D9E75)
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${requirement.unitsFulfilled}',
                  label: AppConfig.modalFulfilledLabel,
                  color: const Color(0xFF1D9E75),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Details ───────────────────────────────────────
          _DetailRow(label: AppConfig.modalUrgencyLabel, value: requirement.urgency),
          _DetailRow(
              label: AppConfig.modalContactLabel,
              value: '${requirement.contactPerson} · ${requirement.contactPhone}'),
          if (requirement.location.isNotEmpty)
            _DetailRow(label: AppConfig.modalLocationLabel, value: requirement.location),
          if (requirement.notes.isNotEmpty)
            _DetailRow(label: AppConfig.modalNotesLabel, value: requirement.notes),

          const SizedBox(height: 4),
        ],
      ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
