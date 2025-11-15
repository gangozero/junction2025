/// Error display widget
library;

/// Error display component
///
/// Shows user-friendly error messages with optional retry action.
/// Displays different layouts based on error severity and context.

import 'package:flutter/material.dart';

import '../../core/error/failures.dart';

/// Error display widget
///
/// Displays error information with icon, message, and optional retry button.
class ErrorDisplay extends StatelessWidget {
  /// Error failure object
  final Failure? failure;

  /// Custom error message (overrides failure message)
  final String? message;

  /// Custom error title
  final String? title;

  /// Retry callback
  final VoidCallback? onRetry;

  /// Whether to show in compact mode (for inline errors)
  final bool compact;

  const ErrorDisplay({
    super.key,
    this.failure,
    this.message,
    this.title,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ?? failure?.userMessage ?? 'An error occurred';
    final errorTitle = title ?? _getTitle();
    final icon = _getIcon();
    final color = _getColor(context);

    if (compact) {
      return _buildCompactError(context, errorMessage, icon, color);
    }

    return _buildFullError(context, errorTitle, errorMessage, icon, color);
  }

  /// Build full error display
  Widget _buildFullError(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build compact error display
  Widget _buildCompactError(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              color: color,
            ),
          ],
        ],
      ),
    );
  }

  /// Get error title based on failure type
  String _getTitle() {
    if (failure == null) return 'Error';

    return switch (failure.runtimeType) {
      NetworkFailure() || TimeoutFailure() => 'Connection Error',
      AuthFailure() => 'Authentication Error',
      ServerFailure() || ApiFailure() => 'Server Error',
      CacheFailure() => 'Storage Error',
      DeviceOfflineFailure() => 'Device Offline',
      ValidationFailure() => 'Validation Error',
      _ => 'Error',
    };
  }

  /// Get error icon based on failure type
  IconData _getIcon() {
    if (failure == null) return Icons.error_outline;

    return switch (failure.runtimeType) {
      NetworkFailure() || TimeoutFailure() => Icons.wifi_off,
      AuthFailure() => Icons.lock_outline,
      ServerFailure() || ApiFailure() => Icons.cloud_off,
      CacheFailure() || SecureStorageFailure() => Icons.storage,
      DeviceOfflineFailure() => Icons.sensors_off,
      ValidationFailure() => Icons.warning_amber,
      PermissionDeniedFailure() => Icons.block,
      _ => Icons.error_outline,
    };
  }

  /// Get error color based on failure severity
  Color _getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (failure == null) return colorScheme.error;

    return switch (failure.runtimeType) {
      NetworkFailure() ||
      TimeoutFailure() ||
      DeviceOfflineFailure() => Colors.orange,
      AuthFailure() || PermissionDeniedFailure() => colorScheme.error,
      ServerFailure() || ApiFailure() => colorScheme.error,
      ValidationFailure() => Colors.amber,
      _ => colorScheme.error,
    };
  }
}

/// Inline error widget
///
/// Compact error display for use within forms or list items.
class InlineError extends StatelessWidget {
  /// Error message
  final String message;

  /// Optional icon
  final IconData? icon;

  const InlineError({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error snackbar helper
class ErrorSnackbar {
  /// Show error snackbar
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }
}
