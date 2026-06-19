import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/zonez_colors.dart';



class CircuitBackground extends StatelessWidget {

  const CircuitBackground({

    super.key,

    this.showSideGlows = false,

    this.showElectronicCircles = false,

  });



  final bool showSideGlows;

  final bool showElectronicCircles;



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;



    return Container(

      color: isDark ? ZonezColors.deepBlack : ZonezColors.lightBackground,

      child: CustomPaint(

        painter: _CircuitPainter(

          showSideGlows: showSideGlows,

          showElectronicCircles: showElectronicCircles,

          isDark: isDark,

        ),

        size: Size.infinite,

      ),

    );

  }

}



class _CircuitPainter extends CustomPainter {

  _CircuitPainter({

    required this.showSideGlows,

    required this.showElectronicCircles,

    required this.isDark,

  });



  final bool showSideGlows;

  final bool showElectronicCircles;

  final bool isDark;

  final _rng = math.Random(42);



  @override

  void paint(Canvas canvas, Size size) {

    if (showElectronicCircles) {

      _paintElectronicCircles(canvas, size);

    }

    if (showSideGlows) {

      _paintSideGlows(canvas, size);

    }

    _paintCircuitLines(canvas, size);

  }



  void _paintElectronicCircles(Canvas canvas, Size size) {

    final purple = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;

    final cyan = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;

    final centers = [

      Offset(size.width * 0.15, size.height * 0.2),

      Offset(size.width * 0.85, size.height * 0.15),

      Offset(size.width * 0.1, size.height * 0.75),

      Offset(size.width * 0.9, size.height * 0.8),

    ];

    for (var i = 0; i < centers.length; i++) {

      final color = i.isEven ? purple : cyan;

      final paint = Paint()

        ..color = color.withValues(alpha: isDark ? 0.06 : 0.04)

        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

      canvas.drawCircle(centers[i], size.width * 0.35, paint);

    }

  }



  void _paintSideGlows(Canvas canvas, Size size) {

    final purple = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;

    final cyan = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;

    final leftPaint = Paint()

      ..shader = LinearGradient(

        colors: [

          purple.withValues(alpha: isDark ? 0.25 : 0.12),

          Colors.transparent,

        ],

        begin: Alignment.centerLeft,

        end: Alignment.centerRight,

      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.15, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, 8, size.height), leftPaint);



    final rightPaint = Paint()

      ..shader = LinearGradient(

        colors: [

          Colors.transparent,

          cyan.withValues(alpha: isDark ? 0.25 : 0.12),

        ],

        begin: Alignment.centerLeft,

        end: Alignment.centerRight,

      ).createShader(

        Rect.fromLTWH(size.width - 8, 0, 8, size.height),

      );

    canvas.drawRect(

      Rect.fromLTWH(size.width - 8, 0, 8, size.height),

      rightPaint,

    );

  }



  void _paintCircuitLines(Canvas canvas, Size size) {

    final accent = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;

    final primary = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;

    final linePaint = Paint()

      ..color = accent.withValues(alpha: isDark ? 0.04 : 0.06)

      ..strokeWidth = 0.8

      ..style = PaintingStyle.stroke;



    final nodePaint = Paint()

      ..color = primary.withValues(alpha: isDark ? 0.08 : 0.06)

      ..style = PaintingStyle.fill;



    for (var i = 0; i < 18; i++) {

      final start = Offset(

        _rng.nextDouble() * size.width,

        _rng.nextDouble() * size.height,

      );

      final end = Offset(

        start.dx + (_rng.nextDouble() - 0.5) * 120,

        start.dy + (_rng.nextDouble() - 0.5) * 120,

      );

      canvas.drawLine(start, end, linePaint);

      canvas.drawCircle(end, 2, nodePaint);

    }

  }



  @override

  bool shouldRepaint(covariant _CircuitPainter oldDelegate) =>

      oldDelegate.isDark != isDark;

}

