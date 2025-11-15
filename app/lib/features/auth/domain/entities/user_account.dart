/// User account entity
library;

/// User account entity
///
/// Represents an authenticated user's account information.
/// This is the domain entity - platform and framework independent.

import 'package:equatable/equatable.dart';

/// User account entity
///
/// Contains user identification and profile information
/// returned after successful authentication.
class UserAccount extends Equatable {
  /// Unique user identifier
  final String userId;

  /// User's email address
  final String email;

  /// User's display name (optional)
  final String? displayName;

  /// Account creation timestamp
  final DateTime? createdAt;

  /// Last login timestamp
  final DateTime? lastLoginAt;

  /// List of sauna controller IDs linked to this account
  final List<String> linkedControllerIds;

  const UserAccount({
    required this.userId,
    required this.email,
    this.displayName,
    this.createdAt,
    this.lastLoginAt,
    this.linkedControllerIds = const [],
  });

  /// Create empty user account (unauthenticated state)
  const UserAccount.empty()
    : userId = '',
      email = '',
      displayName = null,
      createdAt = null,
      lastLoginAt = null,
      linkedControllerIds = const [];

  /// Check if user account is empty (unauthenticated)
  bool get isEmpty => userId.isEmpty && email.isEmpty;

  /// Check if user account is valid (authenticated)
  bool get isNotEmpty => !isEmpty;

  /// Create copy with updated fields
  UserAccount copyWith({
    String? userId,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? linkedControllerIds,
  }) {
    return UserAccount(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      linkedControllerIds: linkedControllerIds ?? this.linkedControllerIds,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    email,
    displayName,
    createdAt,
    lastLoginAt,
    linkedControllerIds,
  ];

  @override
  String toString() =>
      'UserAccount(userId: $userId, email: $email, '
      'displayName: $displayName, linkedControllers: ${linkedControllerIds.length})';
}
