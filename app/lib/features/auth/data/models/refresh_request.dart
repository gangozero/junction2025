/// Refresh token request DTO
library;

/// Refresh token request data transfer object
///
/// DTO for requesting a new access token using a refresh token.

import 'package:equatable/equatable.dart';

/// Refresh token request DTO
///
/// Contains refresh token for obtaining a new access token.
class RefreshRequest extends Equatable {
  /// Refresh token from previous authentication
  final String refreshToken;

  /// Optional device identifier for session tracking
  final String? deviceId;

  const RefreshRequest({required this.refreshToken, this.deviceId});

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
      if (deviceId != null) 'device_id': deviceId,
    };
  }

  /// Create from JSON
  factory RefreshRequest.fromJson(Map<String, dynamic> json) {
    return RefreshRequest(
      refreshToken: json['refresh_token'] as String,
      deviceId: json['device_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [refreshToken, deviceId];

  @override
  String toString() => 'RefreshRequest(deviceId: $deviceId)';
}
