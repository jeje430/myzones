import 'package:flutter/material.dart';

import '../../../../core/theme/zonez_colors.dart';
import '../../../../models/map_lounge.dart';

/// Neon ZONEZ hall pin for flutter_map MarkerLayer.
class ZonezHallPin extends StatelessWidget {
  const ZonezHallPin({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final LoungeCategory category;
  final bool selected;
  final VoidCallback onTap;

  Color get _accent => switch (category) {
        LoungeCategory.ps5 => ZonezColors.neonCyan,
        LoungeCategory.pc => ZonezColors.neonPurple,
        LoungeCategory.mixed => ZonezColors.neonGold,
      };

  @override
  Widget build(BuildContext context) {
    final size = selected ? 52.0 : 44.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size + 12,
        child: CustomPaint(
          painter: _NeonPinPainter(
            accent: _accent,
            selected: selected,
            category: category,
          ),
        ),
      ),
    );
  }
}

/// Pulsing user location marker — GPS only.
class ZonezUserPin extends StatelessWidget {
  const ZonezUserPin({super.key, required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    final outer = 36.0 + (pulse * 14);

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: outer,
            height: outer,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ZonezColors.neonCyan.withValues(alpha: (1 - pulse) * 0.22),
              border: Border.all(
                color: ZonezColors.neonCyan.withValues(alpha: (1 - pulse) * 0.45),
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ZonezColors.neonGradient,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: ZonezColors.neonCyan.withValues(alpha: 0.55),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }
}

class _NeonPinPainter extends CustomPainter {
  _NeonPinPainter({
    required this.accent,
    required this.selected,
    required this.category,
  });

  final Color accent;
  final bool selected;
  final LoungeCategory category;

  @override
  void paint(Canvas canvas, Size size) {
    final headRadius = selected ? 14.0 : 12.0;
    final headCenter = Offset(size.width / 2, headRadius + 4);
    final tip = Offset(size.width / 2, size.height - 2);

    final glow = Paint()
      ..color = accent.withValues(alpha: selected ? 0.5 : 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, selected ? 14 : 10);
    canvas.drawCircle(headCenter, headRadius + (selected ? 8 : 5), glow);

    final body = Path()
      ..addOval(Rect.fromCircle(center: headCenter, radius: headRadius))
      ..moveTo(headCenter.dx - headRadius * 0.5, headCenter.dy + headRadius * 0.45)
      ..quadraticBezierTo(tip.dx, headCenter.dy + headRadius * 1.2, tip.dx, tip.dy)
      ..quadraticBezierTo(
        tip.dx,
        headCenter.dy + headRadius * 1.2,
        headCenter.dx + headRadius * 0.5,
        headCenter.dy + headRadius * 0.45,
      )
      ..close();

    canvas.drawPath(
      body,
      Paint()..color = ZonezColors.cardDark,
    );

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 2
        ..color = accent,
    );

    canvas.drawCircle(
      headCenter,
      headRadius * 0.55,
      Paint()..color = accent.withValues(alpha: 0.85),
    );

    if (selected) {
      canvas.drawCircle(
        headCenter,
        headRadius + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeonPinPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.accent != accent ||
        oldDelegate.category != category;
  }
}
