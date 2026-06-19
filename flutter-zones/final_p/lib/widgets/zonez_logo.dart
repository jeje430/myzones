import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../core/theme/zonez_colors.dart';



class ZonezLogo extends StatelessWidget {

  const ZonezLogo({

    super.key,

    this.size = 48,

    this.showText = true,

    this.imageOnly = false,

    this.compact = false,

  });



  final double size;

  final bool showText;

  final bool imageOnly;

  /// When true, renders a larger proportional mark without a boxed background.

  final bool compact;



  @override

  Widget build(BuildContext context) {

    final onSurface = Theme.of(context).colorScheme.onSurface;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageWidth = compact ? size * 1.55 : size * 1.25;

    final imageHeight = compact ? size * 1.35 : size;



    Widget logoImage = Image.asset(

      'assets/images/logo.png',

      width: imageWidth,

      height: imageHeight,

      fit: BoxFit.contain,

      filterQuality: FilterQuality.high,

      gaplessPlayback: true,

    );



    if (isDark && !imageOnly) {

      logoImage = DecoratedBox(

        decoration: BoxDecoration(

          boxShadow: [

            BoxShadow(

              color: ZonezColors.neonPurple.withValues(alpha: 0.28),

              blurRadius: 22,

              spreadRadius: 0,

            ),

            BoxShadow(

              color: ZonezColors.neonCyan.withValues(alpha: 0.12),

              blurRadius: 30,

              spreadRadius: 2,

            ),

          ],

        ),

        child: logoImage,

      );

    }



    if (imageOnly) {

      return logoImage;

    }



    return Row(

      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.center,

      children: [

        logoImage,

        if (showText) ...[

          SizedBox(width: compact ? 12 : 10),

          Text(

            'ZONES',

            style: GoogleFonts.cairo(

              fontSize: size * (compact ? 0.5 : 0.45),

              fontWeight: FontWeight.bold,

              color: onSurface,

              letterSpacing: 2,

            ),

          ),

        ],

      ],

    );

  }

}



class ZonezLogoLarge extends StatelessWidget {

  const ZonezLogoLarge({super.key, this.width = 220});



  final double width;



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;



    Widget logo = Image.asset(

      'assets/images/logo.png',

      width: width * 0.78,

      fit: BoxFit.contain,

      filterQuality: FilterQuality.high,

    );



    if (isDark) {

      logo = DecoratedBox(

        decoration: BoxDecoration(

          boxShadow: [

            BoxShadow(

              color: ZonezColors.neonPurple.withValues(alpha: 0.35),

              blurRadius: 36,

            ),

          ],

        ),

        child: logo,

      );

    }



    return Column(

      mainAxisSize: MainAxisSize.min,

      children: [

        logo,

        const SizedBox(height: 12),

        ShaderMask(

          shaderCallback: (bounds) => (isDark

                  ? ZonezColors.neonGradient

                  : ZonezColors.lightAccentGradient)

              .createShader(bounds),

          child: Text(

            'ZONEZ',

            style: GoogleFonts.cairo(

              fontSize: width * 0.16,

              fontWeight: FontWeight.bold,

              color: Colors.white,

              letterSpacing: 4,

            ),

          ),

        ),

      ],

    );

  }

}

