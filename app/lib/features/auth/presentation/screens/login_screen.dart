/// Login screen with responsive layout
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/layout_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/email_field.dart';
import '../widgets/login_button.dart';
import '../widgets/password_field.dart';

/// Login screen
///
/// Provides authentication UI with responsive layout:
/// - Mobile: Full-screen centered form
/// - Tablet/Desktop: Centered card with max width
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < LayoutConstants.tabletBreakpoint;

    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              isMobile
                  ? LayoutConstants.paddingMobile
                  : LayoutConstants.paddingDesktop,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 400,
              ),
              child: Card(
                elevation: isMobile ? 0 : 4,
                child: Padding(
                  padding: EdgeInsets.all(
                    isMobile
                        ? LayoutConstants.paddingMobile
                        : LayoutConstants.paddingDesktop,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo or app name
                        Icon(
                          Icons.hot_tub,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.appName,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Email field
                        EmailField(
                          controller: _emailController,
                          enabled: !authState.isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        PasswordField(
                          controller: _passwordController,
                          enabled: !authState.isLoading,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        LoginButton(
                          onPressed: _handleLogin,
                          isLoading: authState.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
