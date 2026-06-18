import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/neon_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final TextEditingController _passwordController;

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: '');
    _passwordController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'يرجى إدخال بريد إلكتروني صالح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (password.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (password.contains(' ')) {
      return 'كلمة المرور لا يجب أن تحتوي على مسافات';
    }
    return null;
  }

  void _login() {
    _passwordController.text = _passwordController.text.trim();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: Stack(
        children: [
          const CircuitBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(),
                    const SizedBox(height: 48),
                    Text(
                      'تسجيل الدخول',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً بعودتك! يرجى تسجيل الدخول للمتابعة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: ZonezColors.textMuted,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 36),
                    NeonTextField(
                      label: 'البريد الإلكتروني',
                      hint: 'example@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    NeonTextField(
                      label: 'كلمة المرور',
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: Icons.lock_outline,
                      showVisibilityToggle: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: null,
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: GoogleFonts.cairo(
                            color: ZonezColors.neonPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    NeonGradientButton(
                      label: 'تسجيل الدخول',
                      onPressed: _login,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
