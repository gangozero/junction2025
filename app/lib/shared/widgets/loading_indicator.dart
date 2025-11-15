/// Loading indicator widget
library;

/// Platform-adaptive loading indicator
///
/// Shows circular progress indicator with optional message.
/// Adapts to platform (Cupertino for iOS, Material for Android/Web).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/utils/platform_utils.dart';

/// Loading indicator widget
///
/// Displays a circular progress indicator with optional message.
/// Automatically adapts to platform conventions.
class LoadingIndicator extends StatelessWidget {
  /// Optional message to display below indicator
  final String? message;

  /// Size of the indicator
  final double size;

  /// Color of the indicator (defaults to theme primary color)
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: PlatformUtils.isIOS
                ? CupertinoActivityIndicator(
                    radius: size / 2,
                    color: indicatorColor,
                  )
                : CircularProgressIndicator(
                    color: indicatorColor,
                    strokeWidth: 3.0,
                  ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading overlay widget
///
/// Semi-transparent overlay with loading indicator.
/// Blocks interaction while showing loading state.
class LoadingOverlay extends StatelessWidget {
  /// Whether overlay is visible
  final bool isLoading;

  /// Widget to show when not loading
  final Widget child;

  /// Optional loading message
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingIndicator(message: message),
          ),
      ],
    );
  }
}

/// Inline loading indicator
///
/// Small loading indicator for use within widgets (e.g., buttons, list items).
class InlineLoadingIndicator extends StatelessWidget {
  /// Size of the indicator
  final double size;

  /// Color of the indicator
  final Color? color;

  const InlineLoadingIndicator({super.key, this.size = 20.0, this.color});

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: PlatformUtils.isIOS
          ? CupertinoActivityIndicator(radius: size / 2, color: indicatorColor)
          : CircularProgressIndicator(color: indicatorColor, strokeWidth: 2.0),
    );
  }
}
