/// Email input field widget
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// Email text field with validation
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;

  const EmailField({
    required this.controller,
    super.key,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: AppStrings.email,
        hintText: 'user@example.com',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      validator: validator ?? _defaultValidator,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emailRequired;
    }

    // Basic email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.emailInvalid;
    }

    return null;
  }
}
