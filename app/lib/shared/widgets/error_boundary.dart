/// Error boundary widget
library;

import 'package:flutter/material.dart';

import '../../core/utils/logger.dart';

/// Error boundary widget
///
/// Catches and displays errors in a user-friendly way,
/// preventing app crashes and showing recovery options.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String errorContext;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.errorContext,
    this.onRetry,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorDisplay(
        error: _error!,
        stackTrace: _stackTrace,
        context: widget.errorContext,
        onRetry: widget.onRetry != null
            ? () {
                setState(() {
                  _error = null;
                  _stackTrace = null;
                });
                widget.onRetry!();
              }
            : null,
      );
    }

    return ErrorHandler(
      onError: (error, stackTrace) {
        AppLogger.e(
          'Error boundary caught error in ${widget.errorContext}',
          error: error,
          stackTrace: stackTrace,
        );
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
      },
      child: widget.child,
    );
  }
}

/// Error handler widget
///
/// Wraps child widget and catches errors using ErrorWidget.builder
class ErrorHandler extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stackTrace) onError;

  const ErrorHandler({super.key, required this.child, required this.onError});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          onError(details.exception, details.stack);
          return ErrorDisplay(
            error: details.exception,
            stackTrace: details.stack,
            context: 'Widget error',
          );
        };
        return child;
      },
    );
  }
}

/// Error display widget
///
/// Displays error information with recovery options
class ErrorDisplay extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final String context;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.stackTrace,
    required this.context,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Error in: ${this.context}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorMessage(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}

/// Feature error boundary
///
/// Pre-configured error boundaries for each feature
class FeatureErrorBoundary extends StatelessWidget {
  final Widget child;
  final String featureName;
  final VoidCallback? onRetry;

  const FeatureErrorBoundary({
    super.key,
    required this.child,
    required this.featureName,
    this.onRetry,
  });

  /// Auth feature error boundary
  factory FeatureErrorBoundary.auth({
    Key? key,
    required Widget child,
    VoidCallback? onRetry,
  }) {
    return FeatureErrorBoundary(
      key: key,
      featureName: 'Authentication',
      onRetry: onRetry,
      child: child,
    );
  }

  /// Dashboard feature error boundary
  factory FeatureErrorBoundary.dashboard({
    Key? key,
    required Widget child,
    VoidCallback? onRetry,
  }) {
    return FeatureErrorBoundary(
      key: key,
      featureName: 'Dashboard',
      onRetry: onRetry,
      child: child,
    );
  }

  /// Control feature error boundary
  factory FeatureErrorBoundary.control({
    Key? key,
    required Widget child,
    VoidCallback? onRetry,
  }) {
    return FeatureErrorBoundary(
      key: key,
      featureName: 'Device Control',
      onRetry: onRetry,
      child: child,
    );
  }

  /// Events feature error boundary
  factory FeatureErrorBoundary.events({
    Key? key,
    required Widget child,
    VoidCallback? onRetry,
  }) {
    return FeatureErrorBoundary(
      key: key,
      featureName: 'Events',
      onRetry: onRetry,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorContext: featureName,
      onRetry: onRetry,
      child: child,
    );
  }
}
