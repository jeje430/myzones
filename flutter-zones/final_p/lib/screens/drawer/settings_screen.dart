import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/zones_data_provider.dart';
import '../../widgets/circuit_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'سياسة الخصوصية',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'نحن في تطبيق ZONEZ نلتزم بحماية خصوصيتك. '
                  'نجمع البيانات الضرورية فقط لتقديم خدمات الحجز والدفع. '
                  'لا نشارك معلوماتك الشخصية مع أطراف ثالثة دون موافقتك. '
                  'يمكنك طلب حذف بياناتك في أي وقت من خلال إعدادات الحساب.\n\n'
                  'البيانات التي نجمعها:\n'
                  '• الاسم ورقم الهاتف والبريد الإلكتروني\n'
                  '• سجل الحجوزات والمدفوعات\n'
                  '• بيانات الاستخدام لتحسين التجربة\n\n'
                  'للاستفسارات: privacy@zonez.app',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: ZonezColors.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إغلاق', style: GoogleFonts.cairo()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف الحساب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف الحساب نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'حذف نهائياً',
              style: GoogleFonts.cairo(color: ZonezColors.deleteRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AppStateProvider>().deleteAccount();
      context.read<ZonesDataProvider>().loadUserProfile();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final appState = context.watch<AppStateProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsCard(
                icon: Icons.notifications_outlined,
                iconColor: isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary,
                title: 'الإشعارات',
                subtitle: appState.pushNotificationsEnabled ? 'مفعّلة' : 'معطّلة',
                onSurface: onSurface,
                trailing: Switch(
                  value: appState.pushNotificationsEnabled,
                  onChanged: appState.setPushNotifications,
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                icon: Icons.alarm_outlined,
                iconColor: isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent,
                title: 'تذكير الحجوزات',
                subtitle: appState.bookingRemindersEnabled
                    ? 'تذكير قبل 30 دقيقة'
                    : 'معطّل',
                onSurface: onSurface,
                trailing: Switch(
                  value: appState.bookingRemindersEnabled,
                  onChanged: appState.setBookingReminders,
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                icon: themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                iconColor: isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent,
                title: 'المظهر',
                subtitle: themeProvider.isDark ? 'الوضع الداكن' : 'الوضع الفاتح',
                onSurface: onSurface,
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                icon: Icons.privacy_tip_outlined,
                iconColor: isDark ? ZonezColors.neonCyan : ZonezColors.lightPrimary,
                title: 'سياسة الخصوصية',
                subtitle: 'اقرأ سياسة الخصوصية والبيانات',
                onSurface: onSurface,
                trailing: Icon(Icons.chevron_left, color: ZonezColors.textMuted),
                onTap: () => _showPrivacyPolicy(context),
              ),
              const SizedBox(height: 32),
              ListTile(
                onTap: () => _confirmDeleteAccount(context),
                leading: const Icon(Icons.delete_forever, color: ZonezColors.deleteRed),
                title: Text(
                  'حذف الحساب',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: ZonezColors.deleteRed,
                  ),
                ),
                subtitle: Text(
                  'حذف نهائي لجميع البيانات',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: ZonezColors.deleteRed.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onSurface,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color onSurface;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ZonezColors.neonPurple.withValues(alpha: 0.2),
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
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: ZonezColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
