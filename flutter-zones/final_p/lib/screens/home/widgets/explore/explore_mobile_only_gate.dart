import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/zonez_colors.dart';
import '../../../../widgets/circuit_background.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/neon_gradient_button.dart';

/// Shown when Explore Map is opened on Chrome/Web — mobile app only.
class ExploreMobileOnlyGate extends StatelessWidget {
  const ExploreMobileOnlyGate({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CircuitBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'استكشف ZONEZ',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: ZonezColors.neonPurple.withValues(alpha: 0.8),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الخريطة متاحة على تطبيق الموبايل فقط',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: ZonezColors.neonCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GlassContainer(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: ZonezColors.neonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: ZonezColors.neonPurple.withValues(alpha: 0.45),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.phone_android_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'لا تستخدم Chrome للخريطة',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'شغّل التطبيق على:\n'
                        '• هاتف Android عبر USB\n'
                        '• أو Android Emulator',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          height: 1.6,
                          color: ZonezColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      NeonGradientButton(
                        label: 'العودة للرئيسية',
                        icon: Icons.home_rounded,
                        onPressed: onGoHome,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'flutter run -d android',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: ZonezColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
