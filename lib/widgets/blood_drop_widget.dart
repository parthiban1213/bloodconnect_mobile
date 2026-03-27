import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ─────────────────────────────────────────────────────────────
//  BloodDropWidget
//
//  Single reusable blood-drop asset loaded from
//  assets/images/blood_drop.svg.
//
//  Usage:
//    BloodDropWidget(size: 96)          // bare drop, any size
//    BloodDropWidget.badge(size: 72)    // inside a rounded badge container
//
//  The SVG viewBox is 100×130 — the drop tip starts at (50,2)
//  and the round belly bottoms out at y≈124. There is 2px of
//  breathing room at the top so the tip is never clipped.
// ─────────────────────────────────────────────────────────────

class BloodDropWidget extends StatelessWidget {
  final double size;
  final Color? color; // optional tint override

  const BloodDropWidget({
    super.key,
    this.size = 80,
    this.color,
  });

  // ── Named constructor: drop inside a soft-red rounded badge ──
  static Widget badge({double badgeSize = 72, Key? key}) {
    // Natural drop aspect ratio from the SVG viewBox (100 wide : 130 tall)
    // Inside the badge we want the drop to fill ~70% of the badge height.
    final dropHeight = badgeSize * 0.70;
    final dropWidth  = dropHeight * (100 / 130);

    return Container(
      key: key,
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        // Soft warm red background matching AppColors.urgentBg
        color: const Color(0xFFFAECE7),
        borderRadius: BorderRadius.circular(badgeSize * 0.30),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/images/blood_drop.svg',
        width:  dropWidth,
        height: dropHeight,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Natural aspect: 100w : 130h
    final w = size * (100 / 130);
    return SvgPicture.asset(
      'assets/images/blood_drop.svg',
      width:  w,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
