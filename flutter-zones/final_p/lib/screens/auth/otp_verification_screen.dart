import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/auth_exception.dart';
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

  bool _isResending = false;
  String? _error;
  String? _success;

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

  String get _email =>
      ModalRoute.of(context)?.settings.arguments as String? ?? '';

  String get _code => _controllers.map((c) => c.text.trim()).join();

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _verify() {
    if (_code.length != 6) {
      setState(() => _error = 'يرجى إدخال رمز مكوّن من 6 أرقام');
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.resetPassword,
      arguments: {'email': _email, 'code': _code},
    );
  }

  Future<void> _resend() async {
    if (_email.isEmpty) return;

    setState(() {
      _isResending = true;
      _error = null;
      _success = null;
    });

    try {
      await AuthRepository.instance.sendPasswordResetCode(email: _email);
      if (!mounted) return;
      setState(() => _success = 'تم إرسال رمز جديد إلى بريدك');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                'تحقق من بريدك الإلكتروني',
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
                                _email,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: ZonezColors.neonCyan,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const fieldCount = 6;
                                  const gap = 6.0;
                                  final fieldWidth = (constraints.maxWidth -
                                          gap * (fieldCount - 1)) /
                                      fieldCount;

                                  return Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Row(
                                      children: List.generate(fieldCount, (i) {
                                        final border = OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: ZonezColors.textMuted
                                                .withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        );

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            left: i > 0 ? gap : 0,
                                          ),
                                          child: SizedBox(
                                            width: fieldWidth,
                                            height: 52,
                                            child: TextField(
                                              controller: _controllers[i],
                                              focusNode: _focusNodes[i],
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 1,
                                              style: GoogleFonts.cairo(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              decoration: InputDecoration(
                                                counterText: '',
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.zero,
                                                hintText: '-',
                                                hintStyle: GoogleFonts.cairo(
                                                  color: ZonezColors.textMuted,
                                                ),
                                                border: border,
                                                enabledBorder: border,
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                  borderSide:
                                                      const BorderSide(
                                                    color:
                                                        ZonezColors.neonPurple,
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
                                  );
                                },
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: GoogleFonts.cairo(
                                    color: ZonezColors.deleteRed,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (_success != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _success!,
                                  style: GoogleFonts.cairo(
                                    color: ZonezColors.neonCyan,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 28),
                              NeonGradientButton(
                                label: 'تحقق من الرمز',
                                onPressed: _verify,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _isResending ? null : _resend,
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: ZonezColors.textMuted,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'لم يصلك الرمز؟ ',
                                      ),
                                      TextSpan(
                                        text: _isResending
                                            ? 'جاري الإرسال...'
                                            : 'أعد الإرسال',
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
