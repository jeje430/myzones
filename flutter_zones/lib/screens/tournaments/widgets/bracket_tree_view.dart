import 'package:flutter/material.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../models/tournament.dart';

/// Layout constants — shared between widgets and connector painter.
abstract final class _BracketMetrics {
  static const matchHeight = 120.0;
  static const matchGap = 20.0;
  static const columnWidth = 210.0;
  static const connectorWidth = 60.0;
  static const headerHeight = 36.0;
  static const canvasPadding = 20.0;

  static double columnContentHeight(int matchCount) {
    if (matchCount <= 0) return matchHeight;
    return matchCount * matchHeight + (matchCount - 1) * matchGap;
  }

  static double matchCenterY(
    int index,
    int count,
    double slotHeight,
    double contentHeight,
  ) {
    if (count <= 0) return contentHeight / 2;
    if (count == 1) return contentHeight / 2;
    final totalChildren = count * slotHeight;
    final gap = (contentHeight - totalChildren) / (count - 1);
    return index * (slotHeight + gap) + slotHeight / 2;
  }
}

String _matchStatusLabel(MatchStatus status) {
  switch (status) {
    case MatchStatus.upcoming:
      return 'قادمة';
    case MatchStatus.live:
      return 'جارية';
    case MatchStatus.completed:
      return 'منتهية';
  }
}

/// Full continuous tournament bracket — scrollable on both axes, no round tabs.
class BracketTreeView extends StatelessWidget {
  const BracketTreeView({super.key, required this.matches});

  final List<BracketMatch> matches;

  List<BracketMatch> _round(BracketRound round) =>
      matches.where((m) => m.round == round).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;
    final connectorPurple = ZonezColors.neonPurple;
    final surface = isDark ? ZonezColors.cardDark : ZonezColors.lightSurface;
    final surfaceAlt =
        isDark ? ZonezColors.inputBg : ZonezColors.lightSurfaceAlt;
    final onSurface = theme.colorScheme.onSurface;
    final muted = isDark ? ZonezColors.textMuted : ZonezColors.lightTextMuted;
    final border = isDark
        ? ZonezColors.neonPurple.withValues(alpha: 0.25)
        : ZonezColors.lightBorder;

    final qf = _round(BracketRound.quarterFinal);
    final sf = _round(BracketRound.semiFinal);
    final fin = _round(BracketRound.finalRound);

    if (qf.isEmpty && sf.isEmpty && fin.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'لم تُحدَّد المباريات بعد',
          textAlign: TextAlign.center,
          style: ZonezTypography.caption(color: muted, context: context),
        ),
      );
    }

    final qfCount = qf.length.clamp(1, 8);
    final contentH = _BracketMetrics.columnContentHeight(qfCount);
    final treeH =
        _BracketMetrics.headerHeight + contentH + _BracketMetrics.canvasPadding * 2;
    final treeW = _BracketMetrics.columnWidth * 3 +
        _BracketMetrics.connectorWidth * 2 +
        _BracketMetrics.canvasPadding * 2;

    final sfSlotHeight = _BracketMetrics.matchHeight * 2 + _BracketMetrics.matchGap;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? null : ZonezColors.lightSurfaceAlt,
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    surfaceAlt.withValues(alpha: 0.5),
                    ZonezColors.cardDark.withValues(alpha: 0.35),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: treeW,
              height: treeH,
              child: Padding(
                padding: const EdgeInsets.all(_BracketMetrics.canvasPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoundColumn(
                      label: bracketRoundLabel(BracketRound.quarterFinal),
                      width: _BracketMetrics.columnWidth,
                      matches: qf,
                      slotHeight: _BracketMetrics.matchHeight,
                      contentHeight: contentH,
                      primary: primary,
                      surface: surface,
                      onSurface: onSurface,
                      muted: muted,
                      isDark: isDark,
                    ),
                    _ConnectorColumn(
                      fromCount: qf.length.clamp(1, 8),
                      toCount: sf.length.clamp(1, 4),
                      fromSlotHeight: _BracketMetrics.matchHeight,
                      toSlotHeight: sfSlotHeight,
                      height: contentH,
                      topOffset: _BracketMetrics.headerHeight,
                      lineColor: connectorPurple,
                      isRtl: isRtl,
                    ),
                    _RoundColumn(
                      label: bracketRoundLabel(BracketRound.semiFinal),
                      width: _BracketMetrics.columnWidth,
                      matches: sf,
                      slotHeight: sfSlotHeight,
                      contentHeight: contentH,
                      primary: primary,
                      surface: surface,
                      onSurface: onSurface,
                      muted: muted,
                      isDark: isDark,
                    ),
                    _ConnectorColumn(
                      fromCount: sf.length.clamp(1, 4),
                      toCount: fin.length.clamp(1, 2),
                      fromSlotHeight: sfSlotHeight,
                      toSlotHeight: contentH,
                      height: contentH,
                      topOffset: _BracketMetrics.headerHeight,
                      lineColor: connectorPurple,
                      isRtl: isRtl,
                    ),
                    _RoundColumn(
                      label: bracketRoundLabel(BracketRound.finalRound),
                      width: _BracketMetrics.columnWidth,
                      matches: fin,
                      slotHeight: contentH,
                      contentHeight: contentH,
                      primary: primary,
                      surface: surface,
                      onSurface: onSurface,
                      muted: muted,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  const _RoundColumn({
    required this.label,
    required this.width,
    required this.matches,
    required this.slotHeight,
    required this.contentHeight,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.isDark,
  });

  final String label;
  final double width;
  final List<BracketMatch> matches;
  final double slotHeight;
  final double contentHeight;
  final Color primary;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundHeader(label: label, primary: primary, isDark: isDark),
          SizedBox(
            height: contentHeight,
            child: Column(
              mainAxisAlignment: matches.length <= 1
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < matches.length; i++)
                  SizedBox(
                    height: matches.length <= 1
                        ? slotHeight.clamp(0, contentHeight)
                        : slotHeight,
                    width: width,
                    child: _BracketMatchNode(
                      match: matches[i],
                      primary: primary,
                      surface: surface,
                      onSurface: onSurface,
                      muted: muted,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  const _RoundHeader({
    required this.label,
    required this.primary,
    required this.isDark,
  });

  final String label;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _BracketMetrics.headerHeight,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? null : primary.withValues(alpha: 0.1),
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.35),
                      ZonezColors.neonPurple.withValues(alpha: 0.2),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Text(
            label,
            style: ZonezTypography.caption(
              size: 12,
              weight: FontWeight.bold,
              color: isDark ? ZonezColors.neonCyan : primary,
              context: context,
            ),
          ),
        ),
      ),
    );
  }
}

class _BracketMatchNode extends StatelessWidget {
  const _BracketMatchNode({
    required this.match,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.isDark,
  });

  final BracketMatch match;
  final Color primary;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final waiting1 =
        match.player1 == null && match.round != BracketRound.quarterFinal;
    final waiting2 =
        match.player2 == null && match.round != BracketRound.quarterFinal;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? null : surface,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  surface.withValues(alpha: 0.95),
                  ZonezColors.inputBg.withValues(alpha: 0.9),
                ],
              )
            : null,
        border: Border.all(
          color: match.isCompleted
              ? primary.withValues(alpha: 0.55)
              : primary.withValues(alpha: isDark ? 0.45 : 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: _OpponentRow(
              name: match.playerLabel(match.player1, match.round),
              statusLabel: waiting1 ? 'فائز' : _matchStatusLabel(match.status),
              isWinner: match.winnerId == match.player1?.id,
              isWaiting: waiting1,
              onSurface: onSurface,
              muted: muted,
              isDark: isDark,
              primary: primary,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? ZonezColors.borderMuted.withValues(alpha: 0.5)
                : ZonezColors.lightBorder,
          ),
          Expanded(
            child: _OpponentRow(
              name: match.playerLabel(match.player2, match.round),
              statusLabel: waiting2 ? 'فائز' : _matchStatusLabel(match.status),
              isWinner: match.winnerId == match.player2?.id,
              isWaiting: waiting2,
              onSurface: onSurface,
              muted: muted,
              isDark: isDark,
              primary: primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentRow extends StatelessWidget {
  const _OpponentRow({
    required this.name,
    required this.statusLabel,
    required this.isWinner,
    required this.isWaiting,
    required this.onSurface,
    required this.muted,
    required this.isDark,
    required this.primary,
  });

  final String name;
  final String statusLabel;
  final bool isWinner;
  final bool isWaiting;
  final Color onSurface;
  final Color muted;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final gold = ZonezColors.neonGold;

    return ColoredBox(
      color: isWinner
          ? gold.withValues(alpha: isDark ? 0.12 : 0.1)
          : isWaiting
              ? (isDark
                  ? gold.withValues(alpha: 0.08)
                  : primary.withValues(alpha: 0.06))
              : Colors.transparent,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZonezTypography.caption(
                    size: 11,
                    weight: isWinner ? FontWeight.bold : FontWeight.w600,
                    color: isWaiting
                        ? (isDark ? gold : primary)
                        : isWinner
                            ? gold
                            : onSurface,
                    context: context,
                  ),
                ),
                Text(
                  isWaiting ? 'بانتظار التأهل' : statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZonezTypography.caption(
                    size: 9,
                    color: muted,
                    context: context,
                  ),
                ),
              ],
            ),
          ),
          if (isWaiting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? ZonezColors.neonGold.withValues(alpha: 0.15)
                    : ZonezColors.lightPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isDark
                      ? ZonezColors.neonGold.withValues(alpha: 0.4)
                      : primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'فائز',
                style: ZonezTypography.caption(
                  size: 9,
                  weight: FontWeight.bold,
                  color: isDark ? ZonezColors.neonGold : primary,
                  context: context,
                ),
              ),
            )
          else if (isWinner)
            const Icon(Icons.emoji_events, size: 14, color: ZonezColors.neonGold),
        ],
      ),
      ),
    );
  }
}

class _ConnectorColumn extends StatelessWidget {
  const _ConnectorColumn({
    required this.fromCount,
    required this.toCount,
    required this.fromSlotHeight,
    required this.toSlotHeight,
    required this.height,
    required this.topOffset,
    required this.lineColor,
    required this.isRtl,
  });

  final int fromCount;
  final int toCount;
  final double fromSlotHeight;
  final double toSlotHeight;
  final double height;
  final double topOffset;
  final Color lineColor;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topOffset),
      child: CustomPaint(
        size: Size(_BracketMetrics.connectorWidth, height),
        painter: _BracketConnectorPainter(
          fromCount: fromCount,
          toCount: toCount,
          fromSlotHeight: fromSlotHeight,
          toSlotHeight: toSlotHeight,
          lineColor: lineColor,
          isRtl: isRtl,
        ),
      ),
    );
  }
}

class _BracketConnectorPainter extends CustomPainter {
  _BracketConnectorPainter({
    required this.fromCount,
    required this.toCount,
    required this.fromSlotHeight,
    required this.toSlotHeight,
    required this.lineColor,
    required this.isRtl,
  });

  final int fromCount;
  final int toCount;
  final double fromSlotHeight;
  final double toSlotHeight;
  final Color lineColor;
  final bool isRtl;

  static const _dashPattern = [5.0, 4.0];
  static const _arrowSize = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;

    final contentH = size.height;
    final elbowX = size.width * 0.5;

    void drawLink(double yFrom, double yTo) {
      final fromX = isRtl ? size.width : 0.0;
      final toX = isRtl ? 0.0 : size.width;
      final midX1 = isRtl ? elbowX : elbowX;
      final midX2 = elbowX;

      final path = Path()
        ..moveTo(fromX, yFrom)
        ..lineTo(midX1, yFrom)
        ..lineTo(midX2, yTo)
        ..lineTo(toX, yTo);

      _drawDashedPath(canvas, path, paint);

      final arrowTip = Offset(toX, yTo);
      _drawArrowhead(canvas, arrowTip, paint, pointingRight: !isRtl);
    }

    if (toCount <= 1) {
      final yTo = _BracketMetrics.matchCenterY(0, 1, toSlotHeight, contentH);
      for (var i = 0; i < fromCount; i++) {
        final yFrom = _BracketMetrics.matchCenterY(
          i,
          fromCount,
          fromSlotHeight,
          contentH,
        );
        drawLink(yFrom, yTo);
      }
    } else {
      for (var i = 0; i < toCount; i++) {
        final yTo = _BracketMetrics.matchCenterY(
          i,
          toCount,
          toSlotHeight,
          contentH,
        );
        final y1a = _BracketMetrics.matchCenterY(
          i * 2,
          fromCount,
          fromSlotHeight,
          contentH,
        );
        drawLink(y1a, yTo);
        if (i * 2 + 1 < fromCount) {
          final y1b = _BracketMetrics.matchCenterY(
            i * 2 + 1,
            fromCount,
            fromSlotHeight,
            contentH,
          );
          drawLink(y1b, yTo);
        }
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      var patternIndex = 0;
      while (distance < metric.length) {
        final segment = _dashPattern[patternIndex % _dashPattern.length];
        final end = distance + segment;
        if (draw) {
          final extractPath = metric.extractPath(
            distance,
            end.clamp(0, metric.length),
          );
          canvas.drawPath(extractPath, paint);
        }
        distance = end;
        draw = !draw;
        patternIndex++;
      }
    }
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset tip,
    Paint paint, {
    required bool pointingRight,
  }) {
    final fill = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingRight) {
      path
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - _arrowSize, tip.dy - _arrowSize * 0.55)
        ..lineTo(tip.dx - _arrowSize, tip.dy + _arrowSize * 0.55)
        ..close();
    } else {
      path
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + _arrowSize, tip.dy - _arrowSize * 0.55)
        ..lineTo(tip.dx + _arrowSize, tip.dy + _arrowSize * 0.55)
        ..close();
    }
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) =>
      oldDelegate.fromCount != fromCount ||
      oldDelegate.toCount != toCount ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.isRtl != isRtl;
}
