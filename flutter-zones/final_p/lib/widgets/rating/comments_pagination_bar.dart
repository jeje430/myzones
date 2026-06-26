import 'package:flutter/material.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/paginated_comments.dart';

/// Paginated navigation for comment lists — prev/next + page indicator.
class CommentsPaginationBar extends StatelessWidget {
  const CommentsPaginationBar({
    super.key,
    required this.meta,
    required this.onPageSelected,
    this.isLoading = false,
  });

  final CommentsPageMeta meta;
  final ValueChanged<int> onPageSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (meta.lastPage <= 1 && meta.total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ZonezColors.inputBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZonezColors.neonPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.chevron_right,
            label: 'السابق',
            enabled: meta.hasPrevious && !isLoading,
            onTap: () => onPageSelected(meta.currentPage - 1),
          ),
          Expanded(
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ZonezColors.neonCyan,
                      ),
                    )
                  : Text(
                      'صفحة ${meta.currentPage} من ${meta.lastPage} • ${meta.total} تعليق',
                      style: ZonezTypography.caption(size: 11),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_left,
            label: 'التالي',
            enabled: meta.hasNext && !isLoading,
            onTap: () => onPageSelected(meta.currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: TextButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18, color: ZonezColors.neonCyan),
        label: Text(label, style: ZonezTypography.caption(size: 11)),
      ),
    );
  }
}
