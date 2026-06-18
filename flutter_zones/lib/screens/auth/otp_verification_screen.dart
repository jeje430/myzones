import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_border.dart';
import '../../widgets/neon_gradient_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _verify() {
    Navigator.pushNamed(context, AppRoutes.resetPassword);
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ??
        'admin@zones.com';

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
                                  gradient: ZonezColors.neonGradient,
                                ),
                                child: const Icon(
                                  Icons.mark_email_read_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'تحقق من بريد إلكتروني',
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لقد أرسلنا رمز تحقق من 6 أرقام إلى',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: ZonezColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: ZonezColors.neonCyan,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(6, (i) {
                                    return Padding(
                                      padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                                      child: SizedBox(
                                        width: 44,
                                        height: 52,
                                        child: TextField(
                                          controller: _controllers[i],
                                          focusNode: _focusNodes[i],
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          maxLength: 1,
                                          style: GoogleFonts.cairo(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            counterText: '',
                                            hintText: '-',
                                            hintStyle: GoogleFonts.cairo(
                                              color: ZonezColors.textMuted,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                color: ZonezColors.neonPurple,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          onChanged: (v) => _onChanged(i, v),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 28),
                              NeonGradientButton(
                                label: 'تحقق من الرمز',
                                onPressed: _verify,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {},
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: ZonezColors.textMuted,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'لم يتم إرسال رمز التحقق؟ ',
                                      ),
                                      TextSpan(
                                        text: 'أعد الإرسال',
                                        style: GoogleFonts.cairo(
                                          color: ZonezColors.neonPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
