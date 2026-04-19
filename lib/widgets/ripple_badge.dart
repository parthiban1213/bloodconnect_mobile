import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  PendingPledgeAnimation
//  Shimmer sweep across the card — amber left border accent.
//  Glow pulse removed per design update.
// ─────────────────────────────────────────────────────────────
class PendingPledgeAnimation extends StatefulWidget {
  final Widget child;
  final bool active;

  const PendingPledgeAnimation({
    super.key,
    required this.child,
    this.active = true,
  });

  @override
  State<PendingPledgeAnimation> createState() =>
      _PendingPledgeAnimationState();
}

class _PendingPledgeAnimationState extends State<PendingPledgeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _shimmerPos;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    // Shimmer sweeps from left (−30 %) to right (130 %)
    _shimmerPos = Tween(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(PendingPledgeAnimation old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _ctrl.repeat();
    } else if (!widget.active && old.active) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ShimmerPainter(position: _shimmerPos.value),
                ),
              ),
            ),
          ],
        ),
      ),
      child: widget.child,
    );
  }
}

// Soft diagonal shimmer beam sliding across the card
class _ShimmerPainter extends CustomPainter {
  final double position;
  _ShimmerPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final x = position * size.width;
    final w = size.width * 0.22;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFF59E0B).withOpacity(0.13),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x - w, 0, w * 2, size.height));
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.position != position;
}

