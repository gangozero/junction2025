/// API session entity
library;

/// API session entity
///
/// Represents an active authenticated session with the vendor API.
/// Contains authentication tokens and session metadata.

import 'package:equatable/equatable.dart';

/// API session entity
///
/// Manages authentication state including ID token (for API auth),
/// access token (for Cognito), refresh token, and session expiration.
class APISession extends Equatable {
  /// ID token for API authorization (used in Bearer header)
  final String idToken;

  /// Access token for Cognito user pool operations
  final String accessToken;

  /// Refresh token for obtaining new tokens
  final String refreshToken;

  /// Token type (always "Bearer")
  final String tokenType;

  /// Token expiration timestamp
  final DateTime expiresAt;

  /// Session creation timestamp
  final DateTime createdAt;

  /// User ID associated with this session
  final String userId;

  const APISession({
    required this.idToken,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresAt,
    required this.createdAt,
    required this.userId,
  });

  /// Create empty session (unauthenticated state)
  APISession.empty()
    : idToken = '',
      accessToken = '',
      refreshToken = '',
      tokenType = 'Bearer',
      expiresAt = DateTime.fromMillisecondsSinceEpoch(0),
      createdAt = DateTime.fromMillisecondsSinceEpoch(0),
      userId = '';

  /// Check if session is empty (no active session)
  bool get isEmpty => idToken.isEmpty && refreshToken.isEmpty;

  /// Check if session is valid (has tokens)
  bool get isNotEmpty => !isEmpty;

  /// Check if access token is expired
  bool get isExpired {
    if (isEmpty) return true;
    return DateTime.now().isAfter(expiresAt);
  }

  /// Check if access token is about to expire (within 5 minutes)
  bool get isExpiringSoon {
    if (isEmpty) return true;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiresAt);
  }

  /// Check if session is valid and not expired
  bool get isValid => isNotEmpty && !isExpired;

  /// Time remaining until token expires
  Duration get timeUntilExpiry {
    if (isEmpty || isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// Create copy with updated fields
  APISession copyWith({
    String? idToken,
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? userId,
  }) {
    return APISession(
      idToken: idToken ?? this.idToken,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
    idToken,
    accessToken,
    refreshToken,
    tokenType,
    expiresAt,
    createdAt,
    userId,
  ];

  @override
  String toString() =>
      'APISession(userId: $userId, tokenType: $tokenType, '
      'expiresAt: $expiresAt, isValid: $isValid, isExpiringSoon: $isExpiringSoon)';
}
