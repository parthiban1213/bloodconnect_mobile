import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  final String urgency;
  final double size;
  final bool large;

  const BloodTypeBadge({
    super.key,
    required this.bloodType,
    required this.urgency,
    this.size = 52,
    this.large = false,
  });

  Color get _bgColor {
    switch (urgency) {
      case 'Critical': return AppColors.urgentBg;
      case 'High': return AppColors.moderateBg;
      case 'Medium': return AppColors.plannedBg;
      default: return AppColors.closedBg;
    }
  }

  Color get _textColor {
    switch (urgency) {
      case 'Critical': return AppColors.urgentText;
      case 'High': return AppColors.moderateText;
      case 'Medium': return AppColors.plannedText;
      default: return AppColors.closedText;
    }
  }

  Color get _labelColor {
    switch (urgency) {
      case 'Critical': return AppColors.urgentAccent;
      case 'High': return AppColors.moderateAccent;
      case 'Medium': return AppColors.plannedAccent;
      default: return AppColors.closedAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 22.0 : 18.0;
    final labelSize = large ? 8.0 : 9.0;

    return Container(
      width: size,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bloodType,
            style: GoogleFonts.dmSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: _textColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'blood type',
            style: GoogleFonts.dmSans(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: _labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
