/// Logout button widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';

/// Logout button
///
/// Triggers logout flow with confirmation dialog
class LogoutButton extends ConsumerWidget {
  final bool showConfirmation;

  const LogoutButton({super.key, this.showConfirmation = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: AppStrings.logout,
      onPressed: authState.isLoading ? null : () => _handleLogout(context, ref),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    if (showConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.logout),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await ref.read(authProvider.notifier).logout();
  }
}
