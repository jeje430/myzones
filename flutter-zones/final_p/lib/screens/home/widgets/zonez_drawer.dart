import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';

import '../../../core/theme/zonez_colors.dart';

import '../../../providers/app_state_provider.dart';

import '../../../providers/zones_data_provider.dart';

import '../../../widgets/zonez_logo.dart';

import '../../profile/profile_screen.dart';

import '../../drawer/notifications_screen.dart';

import '../../drawer/settings_screen.dart';

import '../../drawer/terms_screen.dart';

import '../../drawer/tournaments_screen.dart';
import '../../tournaments/tournament_history_screen.dart';



class ZonezDrawer extends StatelessWidget {

  const ZonezDrawer({super.key});



  void _navigate(BuildContext context, Widget screen) {

    Navigator.pop(context);

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  }



  @override

  Widget build(BuildContext context) {

    final appState = context.watch<AppStateProvider>();

    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final onSurface = theme.colorScheme.onSurface;

    final muted = isDark ? ZonezColors.textMuted : ZonezColors.lightTextMuted;

    final surfaceAlt =

        isDark ? ZonezColors.cardDark : ZonezColors.lightSurfaceAlt;

    final primary = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;



    return Drawer(

      backgroundColor: theme.drawerTheme.backgroundColor,

      child: SafeArea(

        child: Column(

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),

              child: Row(

                children: [

                  IconButton(

                    onPressed: () => Navigator.pop(context),

                    icon: Icon(Icons.close, color: primary),

                  ),

                ],

              ),

            ),

            _buildProfileHeader(

              context,

              appState,

              onSurface: onSurface,

              muted: muted,

              isDark: isDark,

              primary: primary,

            ),

            const SizedBox(height: 16),

            Expanded(

              child: ListView(

                padding: const EdgeInsets.symmetric(horizontal: 16),

                children: [

                  _TournamentsDrawerSection(
                    onSurface: onSurface,
                    muted: muted,
                    surfaceAlt: surfaceAlt,
                    primary: primary,
                    onNavigate: (screen) => _navigate(context, screen),
                  ),

                  _DrawerItem(

                    title: 'الإشعارات',

                    subtitle: 'تابع آخر العروض وحالة حجوزاتك',

                    icon: Icons.notifications_outlined,

                    iconColor: primary,

                    onSurface: onSurface,

                    muted: muted,

                    surfaceAlt: surfaceAlt,

                    onTap: () => _navigate(context, const NotificationsScreen()),

                  ),

                  _DrawerItem(

                    title: 'شروط وقوانين الصالات',

                    subtitle: 'سياسة الحجز والسلوك العام',

                    icon: Icons.description_outlined,

                    iconColor: isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent,

                    onSurface: onSurface,

                    muted: muted,

                    surfaceAlt: surfaceAlt,

                    onTap: () => _navigate(context, const TermsScreen()),

                  ),

                  _DrawerItem(

                    title: 'الإعدادات',

                    subtitle: 'الإشعارات والمظهر',

                    icon: Icons.settings_outlined,

                    iconColor: isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent,

                    onSurface: onSurface,

                    muted: muted,

                    surfaceAlt: surfaceAlt,

                    onTap: () => _navigate(context, const SettingsScreen()),

                  ),

                  _DrawerItem(

                    title: 'تسجيل الخروج',

                    subtitle: 'تسجيل خروج من الحساب',

                    icon: Icons.logout,

                    iconColor: ZonezColors.neonRed,

                    titleColor: ZonezColors.neonRed,

                    onSurface: onSurface,

                    muted: muted,

                    surfaceAlt: surfaceAlt,

                    onTap: () {

                      Navigator.pop(context);

                      Navigator.pushNamedAndRemoveUntil(

                        context,

                        AppRoutes.login,

                        (route) => false,

                      );

                    },

                  ),

                ],

              ),

            ),

            Padding(

              padding: const EdgeInsets.all(24),

              child: Column(

                children: [

                  ZonezLogo(size: 44, showText: true, compact: true),

                  const SizedBox(height: 8),

                  Text(

                    'بوابتك لعالم الألعاب',

                    style: GoogleFonts.cairo(

                      fontSize: 12,

                      color: muted,

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildProfileHeader(

    BuildContext context,

    AppStateProvider appState, {

    required Color onSurface,

    required Color muted,

    required bool isDark,

    required Color primary,

  }) {

    final zonesData = context.watch<ZonesDataProvider>();

    final displayName = zonesData.user?.name ?? appState.userName;

    final displayPhone = zonesData.user?.phone ?? appState.userPhone;

    final accent = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;



    return GestureDetector(

      onTap: () => _navigate(context, const ProfileScreen()),

      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 20),

        child: Column(

          children: [

            Container(

              width: 80,

              height: 80,

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                border: Border.all(color: primary, width: 2),

                boxShadow: [

                  BoxShadow(

                    color: primary.withValues(alpha: 0.35),

                    blurRadius: 16,

                  ),

                ],

              ),

              child: CircleAvatar(

                backgroundColor:

                    isDark ? ZonezColors.inputBg : ZonezColors.lightSurfaceAlt,

                child: Icon(

                  Icons.person,

                  size: 40,

                  color: muted,

                ),

              ),

            ),

            const SizedBox(height: 12),

            Text(

              displayName,

              style: GoogleFonts.cairo(

                fontSize: 18,

                fontWeight: FontWeight.bold,

                color: onSurface,

              ),

            ),

            Text(

              displayPhone,

              style: GoogleFonts.cairo(

                fontSize: 13,

                color: muted,

              ),

            ),

            const SizedBox(height: 8),

            Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Icon(Icons.edit_outlined, size: 14, color: accent),

                const SizedBox(width: 4),

                Text(

                  'عرض الملف الشخصي',

                  style: GoogleFonts.cairo(

                    fontSize: 12,

                    color: accent,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 12),

            Container(

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              decoration: BoxDecoration(

                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: accent.withValues(alpha: 0.5)),

              ),

              child: Row(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Icon(Icons.monetization_on, color: accent, size: 18),

                  const SizedBox(width: 6),

                  Text(

                    'لديك ${appState.loyaltyPoints} نقطة',

                    style: GoogleFonts.cairo(

                      fontSize: 13,

                      color: accent,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _TournamentsDrawerSection extends StatefulWidget {
  const _TournamentsDrawerSection({
    required this.onSurface,
    required this.muted,
    required this.surfaceAlt,
    required this.primary,
    required this.onNavigate,
  });

  final Color onSurface;
  final Color muted;
  final Color surfaceAlt;
  final Color primary;
  final void Function(Widget screen) onNavigate;

  @override
  State<_TournamentsDrawerSection> createState() =>
      _TournamentsDrawerSectionState();
}

class _TournamentsDrawerSectionState extends State<_TournamentsDrawerSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: widget.surfaceAlt.withValues(alpha: isDark ? 0.6 : 1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.transparent
                  : ZonezColors.lightBorder,
            ),
          ),
          child: ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Icon(
              Icons.emoji_events_outlined,
              color: widget.primary,
              size: 26,
            ),
            title: Text(
              'البطولات',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.onSurface,
              ),
            ),
            subtitle: Text(
              'شارك في البطولات وتحدى اللاعبين',
              style: GoogleFonts.cairo(fontSize: 11, color: widget.muted),
            ),
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: widget.muted,
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          _DrawerSubItem(
            title: 'التسجيل في البطولة',
            subtitle: 'تصفح البطولات المتاحة والاشتراك',
            icon: Icons.how_to_reg_outlined,
            onSurface: widget.onSurface,
            muted: widget.muted,
            surfaceAlt: widget.surfaceAlt,
            onTap: () => widget.onNavigate(const TournamentsScreen()),
          ),
          _DrawerSubItem(
            title: 'سجل البطولات',
            subtitle: 'مشاركاتك الحالية والسابقة',
            icon: Icons.history,
            onSurface: widget.onSurface,
            muted: widget.muted,
            surfaceAlt: widget.surfaceAlt,
            onTap: () => widget.onNavigate(const TournamentHistoryScreen()),
          ),
        ],
      ],
    );
  }
}

class _DrawerSubItem extends StatelessWidget {
  const _DrawerSubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSurface,
    required this.muted,
    required this.surfaceAlt,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color onSurface;
  final Color muted;
  final Color surfaceAlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6, right: 12),
      decoration: BoxDecoration(
        color: surfaceAlt.withValues(alpha: isDark ? 0.45 : 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ZonezColors.neonPurple.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: ZonezColors.neonCyan, size: 22),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.cairo(fontSize: 10, color: muted),
        ),
      ),
    );
  }
}



class _DrawerItem extends StatelessWidget {

  const _DrawerItem({

    required this.title,

    required this.subtitle,

    required this.icon,

    required this.iconColor,

    required this.onSurface,

    required this.muted,

    required this.surfaceAlt,

    this.highlighted = false,

    this.titleColor,

    this.onTap,

  });



  final String title;

  final String subtitle;

  final IconData icon;

  final Color iconColor;

  final Color onSurface;

  final Color muted;

  final Color surfaceAlt;

  final bool highlighted;

  final Color? titleColor;

  final VoidCallback? onTap;



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;



    return Container(

      margin: const EdgeInsets.only(bottom: 8),

      decoration: BoxDecoration(

        color: surfaceAlt.withValues(alpha: isDark ? 0.6 : 1),

        borderRadius: BorderRadius.circular(14),

        border: highlighted

            ? Border.all(color: ZonezColors.neonGold.withValues(alpha: 0.6))

            : Border.all(

                color: isDark

                    ? Colors.transparent

                    : ZonezColors.lightBorder,

              ),

        boxShadow: highlighted

            ? [

                BoxShadow(

                  color: ZonezColors.neonGold.withValues(alpha: 0.15),

                  blurRadius: 12,

                ),

              ]

            : isDark

                ? null

                : [

                    BoxShadow(

                      color: Colors.black.withValues(alpha: 0.03),

                      blurRadius: 6,

                      offset: const Offset(0, 2),

                    ),

                  ],

      ),

      child: ListTile(

        onTap: onTap,

        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),

        leading: Icon(icon, color: iconColor, size: 26),

        title: Text(

          title,

          style: GoogleFonts.cairo(

            fontSize: 14,

            fontWeight: FontWeight.bold,

            color: titleColor ?? onSurface,

          ),

        ),

        subtitle: Text(

          subtitle,

          style: GoogleFonts.cairo(fontSize: 11, color: muted),

        ),

      ),

    );

  }

}

