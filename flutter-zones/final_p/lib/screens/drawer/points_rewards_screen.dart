import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../models/reward_milestone.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/circuit_background.dart';

class PointsRewardsScreen extends StatelessWidget {
  const PointsRewardsScreen({super.key});

  void _redeem(BuildContext context, RewardMilestone milestone) {
    final appState = context.read<AppStateProvider>();
    final code = appState.redeemReward(milestone);

    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'نقاطك غير كافية لهذه المكافأة',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تم الاستبدال!',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              milestone.title,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ZonezColors.neonGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ZonezColors.neonGold),
              ),
              child: SelectableText(
                code,
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ZonezColors.neonGold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'استخدم هذا الكود عند الدفع',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: ZonezColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'النقاط والمكافآت',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            ZonezColors.neonPurple.withValues(alpha: 0.4),
                            ZonezColors.neonCyan.withValues(alpha: 0.2),
                          ],
                        )
                      : ZonezColors.lightAccentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: ZonezColors.lightPrimary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 48,
                      color: isDark ? ZonezColors.neonGold : Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${appState.loyaltyPoints} نقطة',
                      style: GoogleFonts.cairo(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? ZonezColors.neonGold : Colors.white,
                      ),
                    ),
                    Text(
                      'رصيدك الحالي',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: isDark
                            ? ZonezColors.textMuted
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'المكافآت المتاحة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 14),
              ...kRewardMilestones.map(
                (milestone) => _MilestoneCard(
                  milestone: milestone,
                  currentPoints: appState.loyaltyPoints,
                  onRedeem: () => _redeem(context, milestone),
                ),
              ),
              if (appState.redeemedCoupons.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'أكواد الخصم',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                ...appState.redeemedCoupons.map(
                  (code) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ZonezColors.neonGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.confirmation_number,
                            color: ZonezColors.neonGold, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          code,
                          style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.currentPoints,
    required this.onRedeem,
  });

  final RewardMilestone milestone;
  final int currentPoints;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final canRedeem = currentPoints >= milestone.pointsRequired;
    final progress = (currentPoints / milestone.pointsRequired).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canRedeem
              ? ZonezColors.neonGold.withValues(alpha: 0.5)
              : ZonezColors.neonPurple.withValues(alpha: 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      '${milestone.pointsRequired} نقطة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: ZonezColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: canRedeem ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem
                      ? ZonezColors.neonGold
                      : ZonezColors.textMuted.withValues(alpha: 0.3),
                  foregroundColor: canRedeem ? Colors.black : Colors.white54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('استبدل', style: GoogleFonts.cairo(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark
                  ? ZonezColors.inputBg
                  : ZonezColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(
                canRedeem ? ZonezColors.neonGold : ZonezColors.neonPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
