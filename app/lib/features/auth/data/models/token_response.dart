/// Token response DTO
library;

/// Token response data transfer object
///
/// DTO for receiving authentication tokens from the API.

import 'package:equatable/equatable.dart';

import '../../domain/entities/api_session.dart';
import '../../domain/entities/user_account.dart';

/// Token response DTO
///
/// Contains authentication tokens and user information
/// returned from the authentication API.
class TokenResponse extends Equatable {
  /// Access token for API requests
  final String accessToken;

  /// Refresh token for obtaining new access tokens
  final String refreshToken;

  /// Token type (usually "Bearer")
  final String tokenType;

  /// Token expiration time in seconds
  final int expiresIn;

  /// User information
  final UserData user;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  /// Create from JSON response
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int,
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }

  /// Convert to domain entities
  ///
  /// Returns a tuple of (APISession, UserAccount) domain entities.
  (APISession, UserAccount) toDomainEntities() {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(seconds: expiresIn));

    final session = APISession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresAt: expiresAt,
      createdAt: now,
      userId: user.id,
    );

    final account = user.toDomain();

    return (session, account);
  }

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
    user,
  ];
}

/// User data DTO
///
/// User information embedded in token response.
class UserData extends Equatable {
  /// User ID
  final String id;

  /// User email
  final String email;

  /// Display name
  final String? displayName;

  /// Account creation timestamp
  final DateTime? createdAt;

  /// Linked controller IDs
  final List<String> linkedControllerIds;

  const UserData({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
    this.linkedControllerIds = const [],
  });

  /// Create from JSON
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      linkedControllerIds:
          (json['linked_controller_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'linked_controller_ids': linkedControllerIds,
    };
  }

  /// Convert to domain UserAccount entity
  UserAccount toDomain() {
    return UserAccount(
      userId: id,
      email: email,
      displayName: displayName,
      createdAt: createdAt,
      lastLoginAt: DateTime.now(),
      linkedControllerIds: linkedControllerIds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    createdAt,
    linkedControllerIds,
  ];
}
