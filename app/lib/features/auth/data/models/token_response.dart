/// Token response DTO
library;

/// Token response data transfer object
///
/// DTO for receiving authentication tokens from the API.

import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../domain/entities/api_session.dart';
import '../../domain/entities/user_account.dart';

/// Token response DTO
///
/// Contains authentication tokens and user information
/// returned from the authentication API (AWS Cognito).
class TokenResponse extends Equatable {
  /// ID token for API authorization (use this in Bearer header)
  final String idToken;

  /// Access token for Cognito user pool operations
  final String accessToken;

  /// Refresh token for obtaining new tokens
  final String refreshToken;

  /// Token expiration time in seconds
  final int expiresIn;

  const TokenResponse({
    required this.idToken,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  /// Create from JSON response (Cognito format)
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      idToken: json['idToken'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  /// Convert to JSON (Cognito format)
  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }

  /// Decode user ID from ID token
  ///
  /// The ID token is a JWT that contains user claims.
  /// We extract the 'sub' (subject) claim which is the user ID.
  String _extractUserIdFromToken() {
    try {
      // JWT structure: header.payload.signature
      final parts = idToken.split('.');
      if (parts.length != 3) {
        throw FormatException('Invalid JWT format');
      }

      // Decode payload (base64url)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      return json['sub'] as String;
    } catch (e) {
      // Fallback to empty string if decoding fails
      return '';
    }
  }

  /// Convert to domain entities
  ///
  /// Returns a tuple of (APISession, UserAccount) domain entities.
  /// Note: User account details need to be fetched separately via GraphQL.
  (APISession, UserAccount) toDomainEntities() {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(seconds: expiresIn));
    final userId = _extractUserIdFromToken();

    final session = APISession(
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: 'Bearer',
      expiresAt: expiresAt,
      createdAt: now,
      userId: userId,
    );

    // Create a temporary user account with minimal info
    // The full user profile should be fetched via GraphQL after login
    final account = UserAccount(
      userId: userId,
      email: '', // Will be populated from GraphQL query
      createdAt: now,
      lastLoginAt: now,
    );

    return (session, account);
  }

  @override
  List<Object?> get props => [idToken, accessToken, refreshToken, expiresIn];
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
