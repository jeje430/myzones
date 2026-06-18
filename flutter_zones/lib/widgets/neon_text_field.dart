import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonTextField extends StatefulWidget {
  const NeonTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon = Icons.email_outlined,
    this.showVisibilityToggle = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.enableIMEPersonalizedLearning = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final bool showVisibilityToggle;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;
  final bool autocorrect;
  final bool enableIMEPersonalizedLearning;

  @override
  State<NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<NeonTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofillHints: widget.autofillHints,
          enableSuggestions: widget.enableSuggestions,
          autocorrect: widget.autocorrect,
          enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
          style: GoogleFonts.cairo(color: onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              widget.prefixIcon,
              color: onSurface.withValues(alpha: 0.7),
              size: 20,
            ),
            suffixIcon: widget.showVisibilityToggle
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
