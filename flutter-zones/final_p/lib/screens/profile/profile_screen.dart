import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';

import '../../models/zones_models.dart';

import '../../providers/app_state_provider.dart';

import '../../providers/zones_data_provider.dart';

import '../../services/profile_avatar_picker.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/zonez_screen.dart';

import '../drawer/edit_profile_screen.dart';



class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});



  @override

  State<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends State<ProfileScreen> {

  bool _avatarUploading = false;

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final zonesData = context.read<ZonesDataProvider>();
      final appState = context.read<AppStateProvider>();

      if (zonesData.user == null) {

        zonesData.loadUserProfile();

      }

      appState.syncLoyaltyFromApi();

    });

  }



  @override

  Widget build(BuildContext context) {

    final zonesData = context.watch<ZonesDataProvider>();

    final appState = context.watch<AppStateProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = zonesData.user;



    return Scaffold(

      appBar: AppBar(

        title: Text('ملفي الشخصي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),

        ),

      ),

      body: Stack(

        children: [

          const CircuitBackground(),

          ZonezScreen(
            top: false,
            child: zonesData.isLoadingProfile

              ? const Center(

                  child: CircularProgressIndicator(color: ZonezColors.neonPurple),

                )

              : zonesData.profileError != null

                  ? Center(

                      child: Text(

                        zonesData.profileError!,

                        style: GoogleFonts.cairo(color: ZonezColors.neonRed),

                      ),

                    )

                  : user == null

                      ? Center(

                          child: Text(

                            'لا توجد بيانات',

                            style: GoogleFonts.cairo(color: ZonezColors.textMuted),

                          ),

                        )

                      : SingleChildScrollView(

                          padding: const EdgeInsets.all(20),

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.stretch,

                            children: [

                              _buildIdentityCard(
                                context,
                                onSurface,
                                user,
                                _avatarUploading,
                              ),

                              const SizedBox(height: 16),

                              _buildLoyaltyCard(context, appState, isDark),

                              const SizedBox(height: 24),

                              _buildInfoSection(onSurface, user, isDark),

                              const SizedBox(height: 24),

                              _buildSettingsSection(context, onSurface, isDark),

                            ],

                          ),

                        ),

          ),

        ],

      ),

    );

  }



  Widget _buildLoyaltyCard(
    BuildContext context,
    AppStateProvider appState,
    bool isDark,
  ) {
    final loyalty = appState.loyaltyStatus;
    final progressPoints = loyalty?.progressPoints ?? 0;
    final progressMax = loyalty?.progressMax ?? appState.nextMilestonePoints;
    final isUnlocked = appState.loyaltyRewardUnlocked;
    final perSession = loyalty?.pointsPerCompletedSession ?? 0;
    final sessionsNeeded = loyalty?.estimatedSessionsRequired ?? 0;
    final sessionsRemaining = loyalty?.sessionsRemaining ?? sessionsNeeded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    ZonezColors.neonPurple.withValues(alpha: isUnlocked ? 0.45 : 0.3),
                    ZonezColors.neonCyan.withValues(alpha: isUnlocked ? 0.25 : 0.15),
                  ],
                )
              : LinearGradient(
                  colors: [
                    ZonezColors.lightPrimary.withValues(alpha: isUnlocked ? 0.18 : 0.12),
                    ZonezColors.lightAccent.withValues(alpha: isUnlocked ? 0.12 : 0.08),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? ZonezColors.neonGold.withValues(alpha: 0.75)
                : (isDark
                    ? ZonezColors.neonGold.withValues(alpha: 0.4)
                    : ZonezColors.lightPrimary.withValues(alpha: 0.3)),
            width: isUnlocked ? 1.6 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: ZonezColors.neonGold.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : (isDark
                  ? null
                  : [
                      BoxShadow(
                        color: ZonezColors.lightPrimary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]),
        ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: isUnlocked
                      ? ZonezColors.neonGold
                      : (isDark ? ZonezColors.neonGold : ZonezColors.lightPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isUnlocked
                        ? 'مكافأة الولاء متاحة!'
                        : 'تقدم نقاط الولاء',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$progressPoints / $progressMax',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isUnlocked ? ZonezColors.neonGold : ZonezColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: appState.loyaltyProgress,
                minHeight: isUnlocked ? 8 : 6,
                backgroundColor: isDark
                    ? ZonezColors.inputBg
                    : ZonezColors.lightBorder,
                valueColor: AlwaysStoppedAnimation(
                  isUnlocked
                      ? ZonezColors.neonGold
                      : (isDark ? ZonezColors.neonGold : ZonezColors.lightPrimary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (perSession > 0)
              Text(
                'كل جلسة مكتملة تمنحك $perSession نقطة ولاء.',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: ZonezColors.textMuted,
                  height: 1.5,
                ),
              ),
            if (sessionsNeeded > 0) ...[
              const SizedBox(height: 4),
              Text(
                isUnlocked
                    ? 'يمكنك الآن حجز جلسة مجانية بمكافأة الولاء.'
                    : 'تحتاج تقريباً $sessionsRemaining جلسة مكتملة لفتح مكافأتك.',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: isUnlocked ? ZonezColors.neonGold : ZonezColors.textMuted,
                  height: 1.5,
                  fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
    );
  }



  Future<void> _pickAvatar(BuildContext context) async {
    if (_avatarUploading) return;

    final bytes = await ProfileAvatarPicker.pickCropAndReadBytes(context);
    if (bytes == null || !context.mounted) return;

    setState(() => _avatarUploading = true);

    final zonesData = context.read<ZonesDataProvider>();
    final ok = await zonesData.uploadProfileAvatar(bytes, filename: 'avatar.jpg');

    if (!context.mounted) return;
    setState(() => _avatarUploading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الصورة بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: ZonezColors.neonPurple,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            zonesData.profileError ?? 'تعذّر رفع الصورة',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
    }
  }

  Future<void> _removeAvatar(BuildContext context) async {
    if (_avatarUploading) return;

    setState(() => _avatarUploading = true);
    final zonesData = context.read<ZonesDataProvider>();
    final ok = await zonesData.deleteProfileAvatar();
    if (!context.mounted) return;
    setState(() => _avatarUploading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف الصورة', style: GoogleFonts.cairo()),
          backgroundColor: ZonezColors.neonPurple,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            zonesData.profileError ?? 'تعذّر حذف الصورة',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
    }
  }

  Widget _buildIdentityCard(
    BuildContext context,
    Color onSurface,
    UserModel user,
    bool isUploading,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ZonezColors.neonPurple.withValues(alpha: 0.3),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isUploading ? null : () => _pickAvatar(context),
            child: Stack(
              alignment: Alignment.bottomLeft,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ZonezColors.neonPurple, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: ZonezColors.neonPurple.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    name: user.name,
                    imageUrl: user.profileImage,
                    radius: 47,
                    fontSize: 24,
                  ),
                ),
                if (isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: ZonezColors.neonCyan,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ZonezColors.neonGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: ZonezColors.cardDark, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isUploading ? 'جاري رفع الصورة...' : 'اضغط لتغيير الصورة',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: ZonezColors.neonCyan,
            ),
          ),
          if (user.profileImage != null && user.profileImage!.isNotEmpty && !isUploading) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _removeAvatar(context),
              icon: const Icon(Icons.delete_outline, size: 16, color: ZonezColors.neonRed),
              label: Text(
                'حذف الصورة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: ZonezColors.neonRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            user.name,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInfoSection(Color onSurface, UserModel user, bool isDark) {

    final fields = [

      (Icons.person_outline, 'الاسم', user.name),

      (Icons.email_outlined, 'البريد الإلكتروني', user.email),

      (Icons.phone_outlined, 'رقم الهاتف', user.phone),

    ];



    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(

          'معلوماتي',

          style: GoogleFonts.cairo(

            fontSize: 16,

            fontWeight: FontWeight.bold,

            color: isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary,

          ),

        ),

        const SizedBox(height: 12),

        Container(

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(

            color: isDark

                ? ZonezColors.cardDark.withValues(alpha: 0.8)

                : ZonezColors.lightSurface,

            borderRadius: BorderRadius.circular(16),

            boxShadow: isDark

                ? null

                : [

                    BoxShadow(

                      color: Colors.black.withValues(alpha: 0.04),

                      blurRadius: 8,

                    ),

                  ],

          ),

          child: Column(

            children: fields

                .map(

                  (f) => _InfoRow(

                    icon: f.$1,

                    label: f.$2,

                    value: f.$3,

                    onSurface: onSurface,

                  ),

                )

                .toList(),

          ),

        ),

      ],

    );

  }



  Widget _buildSettingsSection(

    BuildContext context,

    Color onSurface,

    bool isDark,

  ) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(

          'الإعدادات',

          style: GoogleFonts.cairo(

            fontSize: 16,

            fontWeight: FontWeight.bold,

            color: isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary,

          ),

        ),

        const SizedBox(height: 12),

        _SettingsTile(

          icon: Icons.edit_outlined,

          title: 'تعديل الملف الشخصي',

          subtitle: 'قم بتحديث معلوماتك الشخصية',

          onSurface: onSurface,

          isDark: isDark,

          onTap: () {

            Navigator.push(

              context,

              MaterialPageRoute(builder: (_) => const EditProfileScreen()),

            );

          },

        ),

      ],

    );

  }

}



class _InfoRow extends StatelessWidget {

  const _InfoRow({

    required this.icon,

    required this.label,

    required this.value,

    required this.onSurface,

  });



  final IconData icon;

  final String label;

  final String value;

  final Color onSurface;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(

        children: [

          Icon(icon, color: ZonezColors.neonPurple, size: 22),

          const SizedBox(width: 14),

          Expanded(

            child: Text(

              label,

              style: GoogleFonts.cairo(fontSize: 13, color: onSurface),

            ),

          ),

          Flexible(

            child: Text(

              value,

              textAlign: TextAlign.end,

              style: GoogleFonts.cairo(

                fontSize: 13,

                color: ZonezColors.textMuted,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _SettingsTile extends StatelessWidget {

  const _SettingsTile({

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.onSurface,

    required this.isDark,

    this.onTap,

  });



  final IconData icon;

  final String title;

  final String subtitle;

  final Color onSurface;

  final bool isDark;

  final VoidCallback? onTap;



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color: isDark

              ? ZonezColors.cardDark.withValues(alpha: 0.8)

              : ZonezColors.lightSurface,

          borderRadius: BorderRadius.circular(16),

        ),

        child: Row(

          children: [

            Icon(icon, color: ZonezColors.neonPurple, size: 24),

            const SizedBox(width: 14),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style: GoogleFonts.cairo(

                      fontSize: 14,

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

            Icon(Icons.chevron_left, color: ZonezColors.textMuted),

          ],

        ),

      ),

    );

  }

}

