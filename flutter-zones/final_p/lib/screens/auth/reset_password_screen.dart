import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_border.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/neon_text_field.dart';
import '../../widgets/zonez_logo.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _savePassword() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CircuitBackground(showSideGlows: true),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ZonezLogo(size: 40),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        ),
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: ZonezColors.neonCyan,
                        ),
                        label: Text(
                          'العودة لتسجيل الدخول',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: ZonezColors.neonCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: NeonGradientBorder(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ZonezColors.neonPurple,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_reset,
                                  color: ZonezColors.neonPurple,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 20),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.cairo(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'إعادة ',
                                      style: TextStyle(color: ZonezColors.neonPurple),
                                    ),
                                    TextSpan(text: 'تعيين كلمة المرور'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'قم بإنشاء كلمة مرور جديدة وآمنة لحسابك.',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: ZonezColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              NeonTextField(
                                label: 'كلمة المرور الجديدة',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline,
                                showVisibilityToggle: true,
                              ),
                              const SizedBox(height: 20),
                              NeonTextField(
                                label: 'تأكيد كلمة المرور الجديدة',
                                controller: _confirmController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline,
                                showVisibilityToggle: true,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: ZonezColors.textMuted.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل وتشمل حروفاً وأرقاماً ورموزاً.',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: ZonezColors.textMuted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              NeonGradientButton(
                                label: 'حفظ كلمة المرور',
                                icon: Icons.lock,
                                onPressed: _savePassword,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
