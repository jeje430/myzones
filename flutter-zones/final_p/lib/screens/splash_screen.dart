import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/zonez_colors.dart';
import '../providers/branding_provider.dart';
import '../widgets/branding_logo_image.dart';
import '../widgets/circuit_background.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// RTL row order: first item renders on the right.
  static const _features = [
    (
      Icons.stars_rounded,
      'نقاط وخصومات',
      'اجمع النقاط واستمتع بخصومات حصرية',
    ),
    (
      Icons.credit_card_rounded,
      'دفع آمن',
      'خيارات دفع متعددة وسريعة وآمنة',
    ),
    (
      Icons.event_available_rounded,
      'حجز إلكتروني',
      'احجز جلستك بسهولة ومن أي مكان',
    ),
    (
      Icons.location_on_rounded,
      'صالات قريبة منك',
      'اكتشف أفضل الصالات الأقرب إليك',
    ),
  ];

  void _openLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZonezColors.deepBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CircuitBackground(
            showElectronicCircles: true,
            showSideGlows: true,
          ),
          const _CornerNebula(alignment: Alignment.topLeft),
          const _CornerNebula(alignment: Alignment.topRight),
          const _CornerNebula(alignment: Alignment.bottomLeft),
          const _CornerNebula(alignment: Alignment.bottomRight),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const _LogoSection(),
                  const SizedBox(height: 18),
                  const _SecondaryTagline(),
                  const SizedBox(height: 32),
                  const _FeatureGrid(features: _features),
                  const Spacer(flex: 3),
                  _DiscoverButton(onPressed: () => _openLogin(context)),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerNebula extends StatelessWidget {
  const _CornerNebula({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isPurple = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomRight;
    final color = isPurple ? ZonezColors.neonPurple : ZonezColors.neonCyan;

    return Align(
      alignment: alignment,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 80,
              spreadRadius: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandingLogoImage(
          width: 220,
          height: 190,
          fit: BoxFit.contain,
          showDarkGlow: true,
        ),
        const SizedBox(height: 14),
        Text(
          branding.platformName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.orbitron(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: ZonezColors.neonCyan.withValues(alpha: 0.7),
                blurRadius: 20,
              ),
              Shadow(
                color: ZonezColors.neonPurple.withValues(alpha: 0.5),
                blurRadius: 28,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'السرعة، التنظيم، والمتعة في مكان واحد',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.94),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryTagline extends StatelessWidget {
  const _SecondaryTagline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ZonezColors.neonCyan.withValues(alpha: 0.45),
        ),
        gradient: LinearGradient(
          colors: [
            ZonezColors.neonPurple.withValues(alpha: 0.12),
            ZonezColors.neonCyan.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Text(
        'اكتشف أفضل الصالات القريبة منك',
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.88),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});

  final List<(IconData, String, String)> features;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < features.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 118,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              color: ZonezColors.borderMuted.withValues(alpha: 0.35),
            ),
          Expanded(child: _FeatureItem(feature: features[i])),
        ],
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.feature});

  final (IconData, String, String) feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ZonezColors.neonPurple.withValues(alpha: 0.65),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ZonezColors.neonCyan.withValues(alpha: 0.2),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(
              feature.$1,
              color: ZonezColors.neonCyan,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feature.$2,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feature.$3,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 8,
              color: ZonezColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverButton extends StatelessWidget {
  const _DiscoverButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(32),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: ZonezColors.neonGradient,
                boxShadow: [
                  BoxShadow(
                    color: ZonezColors.neonPurple.withValues(alpha: 0.5),
                    blurRadius: 22,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: ZonezColors.neonCyan.withValues(alpha: 0.28),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                decoration: BoxDecoration(
                  color: ZonezColors.deepBlack.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'اكتشف الصالات الآن',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
