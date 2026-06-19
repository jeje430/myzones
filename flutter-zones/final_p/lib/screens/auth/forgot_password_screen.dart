import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_border.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/neon_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendCode() {
    Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: _emailController.text.isEmpty
          ? 'admin@zones.com'
          : _emailController.text,
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
                const AuthHeader(),
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
                                  Icons.email_outlined,
                                  color: ZonezColors.neonPurple,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'استرجاع كلمة المرور',
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق لإعادة تعيين كلمة المرور.',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: ZonezColors.textMuted,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              NeonTextField(
                                label: 'البريد الإلكتروني',
                                hint: 'example@email.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 28),
                              NeonGradientButton(
                                label: 'إرسال رمز التحقق',
                                onPressed: _sendCode,
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
