import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/zonez_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/zones_data_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/neon_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final zonesData = context.read<ZonesDataProvider>();
    await zonesData.loadUserProfile();
    final user = zonesData.user;
    if (user != null && mounted) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تعبئة جميع الحقول',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final zonesData = context.read<ZonesDataProvider>();
    final appState = context.read<AppStateProvider>();

    final success = await zonesData.updateUserProfile(
          name: name,
          phone: phone,
          email: email,
        );

    if (!mounted) return;

    if (success) {
      appState.updateProfile(name: name, phone: phone);
    }
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ البيانات',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonPurple,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل حفظ البيانات، حاول مرة أخرى',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تعديل الملف الشخصي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: ZonezColors.neonPurple),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: ZonezColors.neonPurple, width: 2),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: ZonezColors.inputBg,
                            child: Icon(Icons.person, size: 44, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      NeonTextField(
                        controller: _nameController,
                        label: 'الاسم',
                        hint: 'أدخل اسمك',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      NeonTextField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        hint: 'أدخل رقم هاتفك',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      NeonTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'أدخل بريدك الإلكتروني',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: ZonezColors.neonPurple,
                              ),
                            )
                          : NeonGradientButton(
                              label: 'حفظ التغييرات',
                              onPressed: _save,
                            ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
