import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/branding/branding_constants.dart';
import '../providers/branding_provider.dart';

/// Cached remote platform logo with seamless local fallback.
class BrandingLogoImage extends StatelessWidget {
  const BrandingLogoImage({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.padding,
    this.filterQuality = FilterQuality.high,
    this.gaplessPlayback = true,
    this.showDarkGlow = false,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final EdgeInsetsGeometry? padding;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final bool showDarkGlow;

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget image = branding.hasRemoteLogo
        ? CachedNetworkImage(
            imageUrl: branding.logoUrl!,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
            placeholder: (_, _) => _fallbackImage(),
            errorWidget: (_, _, _) => _fallbackImage(),
          )
        : _fallbackImage();

    if (padding != null) {
      image = Padding(padding: padding!, child: image);
    }

    if (showDarkGlow && isDark) {
      image = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.28),
              blurRadius: 22,
            ),
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.12),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: image,
      );
    }

    return image;
  }

  Widget _fallbackImage() {
    return Image.asset(
      BrandingConstants.fallbackLogoAsset,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
    );
  }
}
