import 'package:flutter/material.dart';
import 'language_selector.dart';
import 'zonez_logo.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.trailing,
    this.showLanguage = true,
  });

  final Widget? trailing;
  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const ZonezLogo(size: 40),
          if (trailing != null)
            trailing!
          else if (showLanguage)
            const LanguageSelector()
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }
}
