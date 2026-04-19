import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/app_config.dart';

// ─────────────────────────────────────────────────────────────
//  SchedulePledgeModal
//  Shows before a donor taps "I'll Donate". Date and time are
//  now OPTIONAL — donor can pledge immediately without scheduling.
//  Returns a ({scheduledDate, scheduledTime}) record on confirm,
//  or null if cancelled.
// ─────────────────────────────────────────────────────────────

Future<({String scheduledDate, String scheduledTime})?> showSchedulePledgeModal(
  BuildContext context, {
  required String patientName,
  required String bloodType,
}) {
  return showDialog<({String scheduledDate, String scheduledTime})>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: _SchedulePledgeModal(
        patientName: patientName,
        bloodType:   bloodType,
      ),
    ),
  );
}

class _SchedulePledgeModal extends StatefulWidget {
  final String patientName;
  final String bloodType;

  const _SchedulePledgeModal({
    required this.patientName,
    required this.bloodType,
  });

  @override
  State<_SchedulePledgeModal> createState() => _SchedulePledgeModalState();
}

class _SchedulePledgeModalState extends State<_SchedulePledgeModal> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate ?? now,
      firstDate:   now,
      lastDate:    now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary:   AppColors.primary,
            onPrimary: Colors.white,
            surface:   Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _selectedDate = picked; });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context:     context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary:   AppColors.primary,
            onPrimary: Colors.white,
            surface:   Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _selectedTime = picked; });
  }

  void _confirm() {
    // Date and time are optional — send empty strings if not selected
    final dateStr = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : '';
    String timeStr = '';
    if (_selectedTime != null) {
      final hour   = _selectedTime!.hour.toString().padLeft(2, '0');
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      timeStr = '$hour:$minute';
    }
    Navigator.of(context).pop((scheduledDate: dateStr, scheduledTime: timeStr));
  }

  void _clearDate() => setState(() { _selectedDate = null; _selectedTime = null; });

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate != null
        ? DateFormat('d MMM yyyy').format(_selectedDate!)
        : AppConfig.pledgeModalDateHint;
    final timeLabel = _selectedTime != null
        ? _selectedTime!.format(context)
        : AppConfig.pledgeModalTimeHint;
    final hasSchedule = _selectedDate != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Text(
                AppConfig.pledgeModalTitle,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(null),
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

          const SizedBox(height: 6),

          // Blood type + patient context
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.urgentBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.urgentBorder),
              ),
              child: Text(
                widget.bloodType,
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'for ${widget.patientName}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // ── Optional schedule info banner ────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.plannedBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.plannedBorder),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: AppColors.plannedText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppConfig.pledgeModalOptionalNote,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.plannedText,
                    height: 1.45,
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 18),

          // ── Optional schedule section ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConfig.pledgeModalScheduleLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              if (hasSchedule)
                GestureDetector(
                  onTap: _clearDate,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Date picker row
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: _selectedDate != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        dateLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _selectedDate != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: _selectedTime != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        timeLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _selectedTime != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // ── Action buttons ───────────────────────────────────
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      AppConfig.pledgeModalCancelBtn,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _confirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      AppConfig.pledgeModalConfirmBtn,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
