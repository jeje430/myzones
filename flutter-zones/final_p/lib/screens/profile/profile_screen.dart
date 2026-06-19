import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';

import '../../models/zones_models.dart';

import '../../providers/app_state_provider.dart';

import '../../providers/zones_data_provider.dart';

import '../../widgets/circuit_background.dart';

import '../drawer/edit_profile_screen.dart';



class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});



  @override

  State<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends State<ProfileScreen> {

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final zonesData = context.read<ZonesDataProvider>();

      if (zonesData.user == null) {

        zonesData.loadUserProfile();

      }

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

          zonesData.isLoadingProfile

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
                                user.name,
                                appState.profileAvatarBytes,
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

        ],

      ),

    );

  }



  Widget _buildLoyaltyCard(

    BuildContext context,

    AppStateProvider appState,

    bool isDark,

  ) {

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(

          gradient: isDark

              ? LinearGradient(

                  colors: [

                    ZonezColors.neonPurple.withValues(alpha: 0.3),

                    ZonezColors.neonCyan.withValues(alpha: 0.15),

                  ],

                )

              : LinearGradient(
                  colors: [
                    ZonezColors.lightPrimary.withValues(alpha: 0.12),
                    ZonezColors.lightAccent.withValues(alpha: 0.08),
                  ],
                ),

          borderRadius: BorderRadius.circular(16),

          border: Border.all(

            color: isDark

                ? ZonezColors.neonGold.withValues(alpha: 0.4)

                : ZonezColors.lightPrimary.withValues(alpha: 0.3),

          ),

          boxShadow: isDark

              ? null

              : [

                  BoxShadow(

                    color: ZonezColors.lightPrimary.withValues(alpha: 0.1),

                    blurRadius: 12,

                    offset: const Offset(0, 4),

                  ),

                ],

        ),

      child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Icon(

                  Icons.card_giftcard,

                  color: isDark ? ZonezColors.neonGold : ZonezColors.lightPrimary,

                ),

                const SizedBox(width: 10),

                Text(

                  'رصيد النقاط: ${appState.loyaltyPoints} نقطة',

                  style: GoogleFonts.cairo(

                    fontSize: 15,

                    fontWeight: FontWeight.bold,

                    color: Theme.of(context).colorScheme.onSurface,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 12),

            ClipRRect(

              borderRadius: BorderRadius.circular(4),

              child: LinearProgressIndicator(

                value: appState.loyaltyProgress,

                minHeight: 6,

                backgroundColor: isDark

                    ? ZonezColors.inputBg

                    : ZonezColors.lightBorder,

                valueColor: AlwaysStoppedAnimation(

                  isDark ? ZonezColors.neonGold : ZonezColors.lightPrimary,

                ),

              ),

            ),

            const SizedBox(height: 6),

            Text(

              'التالي: ${appState.nextMilestonePoints} نقطة',

              style: GoogleFonts.cairo(

                fontSize: 11,

                color: ZonezColors.textMuted,

              ),

            ),

          ],

        ),

    );

  }



  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    context.read<AppStateProvider>().setProfileAvatar(bytes);
  }

  Widget _buildIdentityCard(
    BuildContext context,
    Color onSurface,
    String name,
    Uint8List? avatarBytes,
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
            onTap: () => _pickAvatar(context),
            child: Stack(
              alignment: Alignment.bottomLeft,
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
                  child: CircleAvatar(
                    backgroundColor: ZonezColors.inputBg,
                    backgroundImage:
                        avatarBytes != null ? MemoryImage(avatarBytes) : null,
                    child: avatarBytes == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white54)
                        : null,
                  ),
                ),
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
            'اضغط لتغيير الصورة',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: ZonezColors.neonCyan,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
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

