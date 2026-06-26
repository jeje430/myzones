import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../screens/auth/login_screen.dart';
import '../../widgets/auth_logo_hero.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/neon_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static final _namePattern = RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$');

  static final _lettersOnlyFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[\u0600-\u06FFa-zA-Z\s]'),
  );

  static final _digitsOnlyFormatter = FilteringTextInputFormatter.digitsOnly;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _required(String? value, {String message = 'هذا الحقل مطلوب'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _validateName(String? value) {
    final required = _required(value, message: 'الاسم الكامل مطلوب');
    if (required != null) return required;

    final name = value!.trim();
    if (!_namePattern.hasMatch(name)) {
      return 'الاسم يجب أن يحتوي على حروف فقط';
    }
    if (name.replaceAll(' ', '').length < 3) {
      return 'يرجى إدخال اسم صحيح (3 أحرف على الأقل)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final required = _required(value, message: 'رقم الهاتف مطلوب');
    if (required != null) return required;

    final digits = value!;
    if (digits.length < 9) {
      return 'رقم الهاتف يجب أن يكون 9 أرقام على الأقل';
    }
    if (digits.length > 15) {
      return 'رقم الهاتف طويل جداً';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value, message: 'البريد الإلكتروني مطلوب');
    if (required != null) return required;

    final email = value!.trim();
    if (!_emailPattern.hasMatch(email)) {
      return 'يرجى إدخال بريد إلكتروني صالح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final required = _required(value, message: 'كلمة المرور مطلوبة');
    if (required != null) return required;

    final password = value!;
    if (password.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (password.contains(' ')) {
      return 'كلمة المرور لا يجب أن تحتوي على مسافات';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final required = _required(value, message: 'تأكيد كلمة المرور مطلوب');
    if (required != null) return required;

    if (value != _passwordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: email,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.login,
            arguments: LoginScreenArgs(
              prefillEmail: state.email,
              successMessage:
                  'تم إنشاء حسابك بنجاح. يرجى تسجيل الدخول للمتابعة.',
            ),
          );
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: ZonezColors.neonRed,
            ),
          );
        }
      },
      builder: (context, state) {
        final isBusy = state is AuthLoading;

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
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: LanguageSelector(),
                    ),
                    const SizedBox(height: 12),
                    const AuthLogoHero(logoWidth: 190),
                    const SizedBox(height: 28),
                    Text(
                      'إنشاء حساب جديد',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أنشئ حسابك وابدأ رحلتك في عالم الألعاب والتحدي',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: ZonezColors.textMuted,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 28),
                    NeonTextField(
                      label: 'الاسم الكامل',
                      hint: 'أدخل اسمك الكامل',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      inputFormatters: [_lettersOnlyFormatter],
                      validator: _validateName,
                    ),
                    const SizedBox(height: 18),
                    NeonTextField(
                      label: 'رقم الهاتف',
                      hint: '912345678',
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.phone_outlined,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        _digitsOnlyFormatter,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 18),
                    NeonTextField(
                      label: 'كلمة المرور',
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: Icons.lock_outline,
                      showVisibilityToggle: true,
                      textInputAction: TextInputAction.next,
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 18),
                    NeonTextField(
                      label: 'تأكيد كلمة المرور',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: Icons.lock_outline,
                      showVisibilityToggle: true,
                      textInputAction: TextInputAction.done,
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) => _signUp(),
                    ),
                    const SizedBox(height: 28),
                    isBusy
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: ZonezColors.neonPurple,
                            ),
                          )
                        : NeonGradientButton(
                            label: 'إنشاء حساب',
                            icon: Icons.person_add_alt_1_rounded,
                            onPressed: _signUp,
                          ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لديك حساب بالفعل؟ ',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: ZonezColors.textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          ),
                          child: Text(
                            'تسجيل الدخول',
                            style: GoogleFonts.cairo(
                              color: ZonezColors.neonCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}
