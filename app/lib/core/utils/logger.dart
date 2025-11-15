/// Logging Utility for Harvia MSGA
///
/// Provides platform-specific logging with configurable log levels
/// and structured output for debugging and monitoring.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global logger instance
///
/// Use this throughout the app for consistent logging:
/// ```dart
/// AppLogger.i('User logged in successfully');
/// AppLogger.e('Failed to fetch devices', error: error, stackTrace: stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: _AppLogPrinter(),
    level: kDebugMode ? Level.debug : Level.info,
    filter: _AppLogFilter(),
  );

  /// Log verbose/trace message (only in debug mode)
  static void t(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log debug message
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error message
  static void f(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log API request
  static void api(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('→ $method $url');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('Headers: $headers');
    }

    if (body != null) {
      buffer.writeln('Body: $body');
    }

    _logger.d(buffer.toString());
  }

  /// Log API response
  static void apiResponse(
    int statusCode,
    String url, {
    dynamic body,
    Duration? duration,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.write('← $statusCode $url');

    if (duration != null) {
      buffer.write(' (${duration.inMilliseconds}ms)');
    }

    buffer.writeln();

    if (body != null) {
      buffer.writeln('Body: $body');
    }

    if (statusCode >= 200 && statusCode < 300) {
      _logger.d(buffer.toString());
    } else if (statusCode >= 400) {
      _logger.e(buffer.toString());
    } else {
      _logger.w(buffer.toString());
    }
  }

  /// Log GraphQL operation
  static void graphql(
    String operation,
    String operationType, {
    Map<String, dynamic>? variables,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('⚡ $operationType: $operation');

    if (variables != null && variables.isNotEmpty) {
      buffer.writeln('Variables: $variables');
    }

    _logger.d(buffer.toString());
  }

  /// Log navigation event
  static void navigation(String from, String to) {
    if (!kDebugMode) return;
    _logger.d('🧭 Navigation: $from → $to');
  }

  /// Log authentication event
  static void auth(String event, {Map<String, dynamic>? details}) {
    final buffer = StringBuffer();
    buffer.write('🔐 Auth: $event');

    if (details != null && details.isNotEmpty) {
      buffer.write(' $details');
    }

    _logger.i(buffer.toString());
  }

  /// Log device event
  static void device(String deviceId, String event) {
    _logger.i('🌡️ Device $deviceId: $event');
  }

  /// Log schedule event
  static void schedule(String scheduleId, String event) {
    _logger.i('⏰ Schedule $scheduleId: $event');
  }

  /// Log notification event
  static void notification(String title, String body) {
    _logger.i('🔔 Notification: $title - $body');
  }

  /// Log background task
  static void background(String task, String status) {
    _logger.i('⚙️ Background: $task - $status');
  }

  /// Log cache operation
  static void cache(String operation, String key, {bool? hit}) {
    final hitStatus = hit == null ? '' : (hit ? ' [HIT]' : ' [MISS]');
    _logger.d('💾 Cache: $operation $key$hitStatus');
  }
}

/// Custom log filter
///
/// Controls which log levels are output based on environment
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only log warnings and above
    if (!kDebugMode) {
      return event.level.index >= Level.warning.index;
    }

    // In debug mode, log everything
    return true;
  }
}

/// Custom log printer
///
/// Formats log output with emojis, timestamps, and platform-specific handling
class _AppLogPrinter extends LogPrinter {
  static const _levelEmojis = {
    Level.trace: '🔍',
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.fatal: '💀',
  };

  static const _levelLabels = {
    Level.trace: 'TRACE',
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARN',
    Level.error: 'ERROR',
    Level.fatal: 'FATAL',
  };

  @override
  List<String> log(LogEvent event) {
    final emoji = _levelEmojis[event.level] ?? '';
    final label = _levelLabels[event.level] ?? 'LOG';
    final message = event.message.toString();
    final time = DateTime.now();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';

    final output = <String>[];

    // Main log line
    if (kIsWeb) {
      // Web: simpler format for browser console
      output.add('$emoji [$label] $message');
    } else {
      // Mobile: detailed format
      output.add('$emoji [$timeStr] [$label] $message');
    }

    // Error details
    if (event.error != null) {
      output.add('Error: ${event.error}');
    }

    // Stack trace
    if (event.stackTrace != null) {
      output.add('Stack trace:');
      output.add(event.stackTrace.toString());
    }

    // Send to platform-specific loggers
    _logToPlatform(event.level, message, event.error, event.stackTrace);

    return output;
  }

  /// Send logs to platform-specific logging systems
  void _logToPlatform(
    Level level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (kIsWeb) {
      // Web: logs automatically go to browser console via print
      return;
    }

    // iOS/Android: use dart:developer log
    developer.log(
      message,
      name: 'HarviaMSGA',
      error: error,
      stackTrace: stackTrace,
      level: _convertLevel(level),
    );
  }

  /// Convert logger level to dart:developer level
  int _convertLevel(Level level) {
    return switch (level) {
      Level.trace => 500, // FINEST
      Level.debug => 700, // FINE
      Level.info => 800, // INFO
      Level.warning => 900, // WARNING
      Level.error => 1000, // SEVERE
      Level.fatal => 1200, // SHOUT
      _ => 800,
    };
  }
}
