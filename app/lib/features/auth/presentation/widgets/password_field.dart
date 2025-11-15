/// Password input field widget
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// Password text field with visibility toggle
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const PasswordField({
    required this.controller,
    super.key,
    this.enabled = true,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: AppStrings.password,
        hintText: 'Enter password',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
        border: const OutlineInputBorder(),
      ),
      validator: widget.validator ?? _defaultValidator,
      onFieldSubmitted: widget.onSubmitted,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }

    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }

    return null;
  }
}
