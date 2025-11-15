/// API session entity
library;

/// API session entity
///
/// Represents an active authenticated session with the vendor API.
/// Contains authentication tokens and session metadata.

import 'package:equatable/equatable.dart';

/// API session entity
///
/// Manages authentication state including access token,
/// refresh token, and session expiration.
class APISession extends Equatable {
  /// Access token for API requests
  final String accessToken;

  /// Refresh token for obtaining new access tokens
  final String refreshToken;

  /// Token type (usually "Bearer")
  final String tokenType;

  /// Access token expiration timestamp
  final DateTime expiresAt;

  /// Session creation timestamp
  final DateTime createdAt;

  /// User ID associated with this session
  final String userId;

  const APISession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresAt,
    required this.createdAt,
    required this.userId,
  });

  /// Create empty session (unauthenticated state)
  APISession.empty()
    : accessToken = '',
      refreshToken = '',
      tokenType = 'Bearer',
      expiresAt = DateTime.fromMillisecondsSinceEpoch(0),
      createdAt = DateTime.fromMillisecondsSinceEpoch(0),
      userId = '';

  /// Check if session is empty (no active session)
  bool get isEmpty => accessToken.isEmpty && refreshToken.isEmpty;

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
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? userId,
  }) {
    return APISession(
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
