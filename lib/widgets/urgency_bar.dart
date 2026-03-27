import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/blood_requirement.dart';
import '../utils/app_extensions.dart';

class UrgencyBar extends StatelessWidget {
  final BloodRequirement requirement;

  const UrgencyBar({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final color = UrgencyHelper.barColor(requirement.urgency);
    final progress = UrgencyHelper.urgencyProgress(
        requirement.urgency, requirement.requiredBy);
    final timeText = requirement.requiredBy != null
        ? UrgencyHelper.timeRemaining(requirement.requiredBy)
        : UrgencyHelper.urgencyLabel(requirement.urgency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              timeText,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            Text(
              '${requirement.unitsRequired} unit${requirement.unitsRequired > 1 ? 's' : ''} needed',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: const Color(0xFFB8A898),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1EFE8),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
