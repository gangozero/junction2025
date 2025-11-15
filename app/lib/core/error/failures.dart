/// Error Handling Framework for Harvia MSGA
///
/// Defines failure classes used throughout the application for consistent
/// error handling and user feedback.
library;

import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
///
/// All failures are immutable and comparable via Equatable
abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];

  /// User-friendly error message for display
  String get userMessage => message ?? 'An unexpected error occurred';
}

// ============================================================================
// NETWORK FAILURES
// ============================================================================

/// Network connectivity failure
///
/// Thrown when device has no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);

  @override
  String get userMessage =>
      message ?? 'No internet connection. Please check your network settings.';
}

/// HTTP timeout failure
///
/// Thrown when request exceeds timeout threshold
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message]);

  @override
  String get userMessage => message ?? 'Request timed out. Please try again.';
}

/// Server error failure (5xx)
///
/// Thrown when server returns 500-599 status codes
class ServerFailure extends Failure {
  const ServerFailure([super.message, this.statusCode]);

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String get userMessage =>
      message ?? 'Server error occurred. Please try again later.';
}

// ============================================================================
// AUTHENTICATION FAILURES
// ============================================================================

/// Authentication failure
///
/// Thrown when authentication fails (invalid credentials, expired tokens, etc.)
class AuthFailure extends Failure {
  const AuthFailure([super.message, this.reason]);

  final AuthFailureReason? reason;

  @override
  List<Object?> get props => [message, reason];

  @override
  String get userMessage {
    if (message != null) return message!;

    return switch (reason) {
      AuthFailureReason.invalidCredentials =>
        'Invalid email or password. Please try again.',
      AuthFailureReason.tokenExpired =>
        'Your session has expired. Please log in again.',
      AuthFailureReason.tokenInvalid =>
        'Authentication error. Please log in again.',
      AuthFailureReason.refreshFailed =>
        'Session refresh failed. Please log in again.',
      AuthFailureReason.unauthorized =>
        'You are not authorized to access this resource.',
      _ => 'Authentication failed. Please log in again.',
    };
  }
}

/// Reasons for authentication failure
enum AuthFailureReason {
  invalidCredentials,
  tokenExpired,
  tokenInvalid,
  refreshFailed,
  unauthorized,
  unknown,
}

// ============================================================================
// API FAILURES
// ============================================================================

/// API request failure
///
/// Thrown when API returns error response (4xx, validation errors, etc.)
class ApiFailure extends Failure {
  const ApiFailure([super.message, this.statusCode, this.errors]);

  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  List<Object?> get props => [message, statusCode, errors];

  @override
  String get userMessage {
    if (message != null) return message!;

    return switch (statusCode) {
      400 => 'Invalid request. Please check your input.',
      404 => 'Resource not found.',
      409 => 'Conflict occurred. Please refresh and try again.',
      422 => _validationMessage,
      429 => 'Too many requests. Please wait and try again.',
      _ => 'API error occurred. Please try again.',
    };
  }

  String get _validationMessage {
    if (errors != null && errors!.isNotEmpty) {
      final firstError = errors!.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }
    return 'Validation failed. Please check your input.';
  }
}

/// GraphQL-specific failure
///
/// Thrown when GraphQL query/mutation/subscription fails
class GraphQLFailure extends Failure {
  const GraphQLFailure([super.message, this.errors]);

  final List<dynamic>? errors;

  @override
  List<Object?> get props => [message, errors];

  @override
  String get userMessage {
    if (message != null) return message!;

    if (errors != null && errors!.isNotEmpty) {
      final firstError = errors!.first;
      if (firstError is Map && firstError.containsKey('message')) {
        return firstError['message'].toString();
      }
      return firstError.toString();
    }

    return 'GraphQL request failed. Please try again.';
  }
}

// ============================================================================
// CACHE/STORAGE FAILURES
// ============================================================================

/// Cache failure
///
/// Thrown when local cache read/write operations fail
class CacheFailure extends Failure {
  const CacheFailure([super.message, this.operation]);

  final CacheOperation? operation;

  @override
  List<Object?> get props => [message, operation];

  @override
  String get userMessage {
    if (message != null) return message!;

    return switch (operation) {
      CacheOperation.read => 'Failed to read cached data.',
      CacheOperation.write => 'Failed to save data locally.',
      CacheOperation.delete => 'Failed to delete cached data.',
      CacheOperation.clear => 'Failed to clear cache.',
      _ => 'Local storage error occurred.',
    };
  }
}

/// Cache operations that can fail
enum CacheOperation { read, write, delete, clear }

/// Secure storage failure
///
/// Thrown when secure storage (keychain/keystore/IndexedDB) operations fail
class SecureStorageFailure extends Failure {
  const SecureStorageFailure([super.message]);

  @override
  String get userMessage =>
      message ?? 'Secure storage error. Please try again.';
}

// ============================================================================
// VALIDATION FAILURES
// ============================================================================

/// Validation failure
///
/// Thrown when user input or data validation fails
class ValidationFailure extends Failure {
  const ValidationFailure([super.message, this.field]);

  final String? field;

  @override
  List<Object?> get props => [message, field];

  @override
  String get userMessage {
    if (message != null) return message!;
    if (field != null) return 'Invalid $field. Please check and try again.';
    return 'Validation error. Please check your input.';
  }
}

/// Temperature validation failure
///
/// Thrown when temperature value is outside safe range
class TemperatureValidationFailure extends ValidationFailure {
  const TemperatureValidationFailure([
    String? message,
    this.value,
    this.min,
    this.max,
  ]) : super(message, 'temperature');

  final double? value;
  final double? min;
  final double? max;

  @override
  List<Object?> get props => [message, field, value, min, max];

  @override
  String get userMessage {
    if (message != null) return message!;
    if (min != null && max != null) {
      return 'Temperature must be between ${min!.toInt()}°C and ${max!.toInt()}°C.';
    }
    return 'Invalid temperature value.';
  }
}

// ============================================================================
// DEVICE FAILURES
// ============================================================================

/// Device offline failure
///
/// Thrown when attempting to control an offline sauna controller
class DeviceOfflineFailure extends Failure {
  const DeviceOfflineFailure([super.message, this.deviceId]);

  final String? deviceId;

  @override
  List<Object?> get props => [message, deviceId];

  @override
  String get userMessage =>
      message ?? 'Device is offline. Cannot perform this action.';
}

/// Device command failure
///
/// Thrown when device command fails to execute
class DeviceCommandFailure extends Failure {
  const DeviceCommandFailure([super.message, this.commandType]);

  final String? commandType;

  @override
  List<Object?> get props => [message, commandType];

  @override
  String get userMessage {
    if (message != null) return message!;
    if (commandType != null) {
      return 'Failed to execute $commandType command.';
    }
    return 'Device command failed. Please try again.';
  }
}

// ============================================================================
// SCHEDULE FAILURES
// ============================================================================

/// Schedule conflict failure
///
/// Thrown when schedule overlaps with existing schedule
class ScheduleConflictFailure extends Failure {
  const ScheduleConflictFailure([super.message]);

  @override
  String get userMessage =>
      message ?? 'Schedule conflicts with an existing schedule.';
}

/// Schedule validation failure
///
/// Thrown when schedule parameters are invalid
class ScheduleValidationFailure extends ValidationFailure {
  const ScheduleValidationFailure([String? message])
    : super(message, 'schedule');

  @override
  String get userMessage =>
      message ?? 'Invalid schedule configuration. Please check your settings.';
}

// ============================================================================
// PLATFORM FAILURES
// ============================================================================

/// Platform not supported failure
///
/// Thrown when feature is not supported on current platform
class PlatformNotSupportedFailure extends Failure {
  const PlatformNotSupportedFailure([super.message, this.feature]);

  final String? feature;

  @override
  List<Object?> get props => [message, feature];

  @override
  String get userMessage {
    if (message != null) return message!;
    if (feature != null) {
      return '$feature is not supported on this platform.';
    }
    return 'This feature is not supported on your device.';
  }
}

/// Permission denied failure
///
/// Thrown when required permission is denied
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([super.message, this.permission]);

  final String? permission;

  @override
  List<Object?> get props => [message, permission];

  @override
  String get userMessage {
    if (message != null) return message!;
    if (permission != null) {
      return '$permission permission is required. Please enable it in settings.';
    }
    return 'Permission required. Please enable it in settings.';
  }
}

// ============================================================================
// GENERIC FAILURES
// ============================================================================

/// Unknown failure
///
/// Thrown when error type cannot be determined
class UnknownFailure extends Failure {
  const UnknownFailure([super.message, this.originalError]);

  final Object? originalError;

  @override
  List<Object?> get props => [message, originalError];

  @override
  String get userMessage =>
      message ?? 'An unexpected error occurred. Please try again.';
}

/// Parsing failure
///
/// Thrown when data parsing/deserialization fails
class ParsingFailure extends Failure {
  const ParsingFailure([super.message, this.dataType]);

  final String? dataType;

  @override
  List<Object?> get props => [message, dataType];

  @override
  String get userMessage =>
      message ?? 'Failed to process server response. Please try again.';
}
