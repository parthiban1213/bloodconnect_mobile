import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/blood_requirement.dart';
import '../../utils/app_theme.dart';
import '../../widgets/blood_type_badge.dart';

// ─────────────────────────────────────────────────────────────
//  RequestStatusModal
//  Bottom-sheet popup opened from My Requests screen.
//  Shows: donors received, units remaining, fulfillment progress.
// ─────────────────────────────────────────────────────────────

void showRequestStatusModal(BuildContext context, BloodRequirement req) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RequestStatusModal(requirement: req),
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
    // 62px nav pill + 14px bottom margin + extra safe area
    final navBarHeight = 76.0 + MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, navBarHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                  label: 'Donors',
                  color: AppColors.plannedAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.bloodtype_outlined,
                  value: '${requirement.remainingUnits}',
                  label: 'Units Remaining',
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
                  label: 'Fulfilled',
                  color: const Color(0xFF1D9E75),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Details ───────────────────────────────────────
          _DetailRow(label: 'Urgency', value: requirement.urgency),
          _DetailRow(
              label: 'Contact',
              value: '${requirement.contactPerson} · ${requirement.contactPhone}'),
          if (requirement.location.isNotEmpty)
            _DetailRow(label: 'Location', value: requirement.location),
          if (requirement.notes.isNotEmpty)
            _DetailRow(label: 'Notes', value: requirement.notes),

          const SizedBox(height: 8),

          // ── Close ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
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
