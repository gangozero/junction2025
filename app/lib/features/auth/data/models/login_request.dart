/// Login request DTO
library;

/// Login request data transfer object
///
/// DTO for sending login credentials to the authentication API.

import 'package:equatable/equatable.dart';

/// Login request DTO
///
/// Contains user credentials for authentication.
class LoginRequest extends Equatable {
  /// User's email address
  final String email;

  /// User's password
  final String password;

  /// Optional device identifier for session tracking
  final String? deviceId;

  /// Optional device name for display in session list
  final String? deviceName;

  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceId,
    this.deviceName,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
    };
  }

  /// Create from JSON
  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [email, password, deviceId, deviceName];

  @override
  String toString() =>
      'LoginRequest(email: $email, deviceId: $deviceId, '
      'deviceName: $deviceName)';
}
