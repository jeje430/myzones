import 'package:flutter/material.dart';

import '../core/theme/zonez_colors.dart';
import '../core/theme/zonez_typography.dart';
import '../core/utils/media_url_resolver.dart';

/// Circular user avatar with network image or initials fallback (dark-mode friendly).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.fontSize,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrlResolver.resolve(imageUrl);
    final initials = _initials(name);
    final hasImage = resolved != null && resolved.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: ZonezColors.neonPurple.withValues(alpha: 0.25),
      backgroundImage: hasImage ? NetworkImage(resolved) : null,
      child: hasImage
          ? null
          : initials.isNotEmpty
              ? Text(
                  initials,
                  style: ZonezTypography.accent(
                    size: fontSize ?? (radius * 0.55),
                  ),
                )
              : Icon(Icons.person, size: radius, color: Colors.white54),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final word = parts.first;
      if (word.isEmpty) return '';
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word[0].toUpperCase();
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}
