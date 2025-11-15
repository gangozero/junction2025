/// Command response DTO (Data Transfer Object)
library;

import '../../domain/entities/command_request.dart';

/// Command response DTO from GraphQL mutations
class CommandResponseDto {
  final bool success;
  final String? message;
  final String? errorCode;
  final Map<String, dynamic>? data;

  const CommandResponseDto({
    required this.success,
    this.message,
    this.errorCode,
    this.data,
  });

  /// Create from GraphQL JSON response
  factory CommandResponseDto.fromJson(Map<String, dynamic> json) {
    return CommandResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (errorCode != null) 'errorCode': errorCode,
      if (data != null) 'data': data,
    };
  }

  /// Update command status based on response
  CommandRequest updateCommand(CommandRequest original) {
    return original.copyWith(
      status: success ? CommandStatus.completed : CommandStatus.failed,
      completedAt: DateTime.now(),
      errorMessage: success ? null : (message ?? 'Command failed'),
    );
  }

  /// Check if error is retryable
  bool get isRetryable {
    if (success) return false;

    // Network errors, timeouts, server errors are retryable
    final retryableCodes = [
      'NETWORK_ERROR',
      'TIMEOUT',
      'SERVER_ERROR',
      'SERVICE_UNAVAILABLE',
    ];

    return errorCode != null && retryableCodes.contains(errorCode);
  }

  /// Check if error is due to device offline
  bool get isDeviceOffline {
    return errorCode == 'DEVICE_OFFLINE' ||
        errorCode == 'DEVICE_UNREACHABLE' ||
        message?.toLowerCase().contains('offline') == true;
  }

  /// Check if error is due to invalid command
  bool get isInvalidCommand {
    return errorCode == 'INVALID_COMMAND' ||
        errorCode == 'VALIDATION_ERROR' ||
        message?.toLowerCase().contains('invalid') == true;
  }
}
