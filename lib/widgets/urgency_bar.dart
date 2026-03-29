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
    final isPlanned = requirement.urgency == 'Medium' && requirement.requiredBy == null;

    // Dot count: 1 = low urgency, 2 = moderate, 3 = critical
    final segments = isPlanned ? 1 : (progress >= 0.75 ? 3 : (progress >= 0.45 ? 2 : 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final filled = i < segments;
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? color : const Color(0xFFE8E4DC),
              ),
            );
          }),
        ),
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
    );
  }
}
