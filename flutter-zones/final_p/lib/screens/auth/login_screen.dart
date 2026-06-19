import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../models/auth_exception.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/zones_data_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/neon_text_field.dart';

/// Optional args when returning from sign-up → login.
class LoginScreenArgs {
  const LoginScreenArgs({
    this.prefillEmail,
    this.successMessage,
  });

  final String? prefillEmail;
  final String? successMessage;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final TextEditingController _passwordController;

  String? _authError;
  String? _successMessage;
  bool _routeArgsApplied = false;

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: '');
    _passwordController.clear();
    _emailController.addListener(_clearAuthError);
    _passwordController.addListener(_clearAuthError);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsApplied) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LoginScreenArgs) {
      _routeArgsApplied = true;
      if (args.prefillEmail != null) {
        _emailController.text = args.prefillEmail!;
      }
      _successMessage = args.successMessage;
    } else if (args is Map) {
      _routeArgsApplied = true;
      final email = args['email'] as String?;
      if (email != null) {
        _emailController.text = email;
      }
      _successMessage = args['successMessage'] as String?;
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearAuthError);
    _passwordController.removeListener(_clearAuthError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearAuthError() {
    if (_authError != null) {
      setState(() => _authError = null);
    }
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

  Future<void> _login() async {
    _passwordController.text = _passwordController.text.trim();
    setState(() {
      _authError = null;
      _successMessage = null;
    });

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final auth = context.read<AuthProvider>();
    final appState = context.read<AppStateProvider>();
    final zonesData = context.read<ZonesDataProvider>();

    try {
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        appState: appState,
        zonesData: zonesData,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _authError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final auth = context.watch<AuthProvider>();

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
                    if (_authError != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _authError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ZonezColors.neonRed,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _successMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ZonezColors.neonCyan,
                          height: 1.45,
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 16),
                    auth.isBusy
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: ZonezColors.neonPurple,
                            ),
                          )
                        : NeonGradientButton(
                            label: 'تسجيل الدخول',
                            onPressed: _login,
                          ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.signUp,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: ZonezColors.neonCyan,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'إنشاء حساب',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: ZonezColors.neonCyan,
                            shadows: [
                              Shadow(
                                color: ZonezColors.neonCyan.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
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
  }
}
