import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/zonez_colors.dart';
import '../models/push_message.dart';

class ForegroundNotificationBanner extends StatelessWidget {
  const ForegroundNotificationBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    required this.onTap,
  });

  final PushMessage message;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ZonezColors.neonPurple.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: ZonezColors.neonPurple.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.title,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.body,
                          style: GoogleFonts.cairo(
                            color: ZonezColors.textMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, color: ZonezColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
