/// Auth repository interface
library;

/// Authentication repository interface
///
/// Defines contracts for authentication operations.
/// Implementations handle token management, user authentication,
/// and session lifecycle.

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/api_session.dart';
import '../entities/user_account.dart';

/// Authentication repository interface
///
/// Provides methods for user authentication, token management,
/// and session lifecycle operations.
abstract class AuthRepository {
  /// Login with email and password
  ///
  /// Returns `Either<Failure, (APISession, UserAccount)>` tuple on success.
  ///
  /// Possible failures:
  /// - [NetworkFailure]: Network connection error
  /// - [AuthFailure]: Invalid credentials or authentication error
  /// - [ServerFailure]: Server error during authentication
  Future<Either<Failure, (APISession, UserAccount)>> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
  });

  /// Refresh access token using refresh token
  ///
  /// Returns `Either<Failure, APISession>` with new access token.
  ///
  /// Possible failures:
  /// - [NetworkFailure]: Network connection error
  /// - [AuthFailure]: Invalid or expired refresh token
  /// - [ServerFailure]: Server error during token refresh
  Future<Either<Failure, APISession>> refreshToken({
    required String refreshToken,
    String? deviceId,
  });

  /// Revoke authentication tokens
  ///
  /// Invalidates both access and refresh tokens on the server.
  ///
  /// Possible failures:
  /// - [NetworkFailure]: Network connection error
  /// - [ServerFailure]: Server error during revocation
  Future<Either<Failure, void>> revokeToken({
    required String accessToken,
    required String refreshToken,
  });

  /// Logout user
  ///
  /// Revokes tokens on server and clears local session data.
  ///
  /// Possible failures:
  /// - [NetworkFailure]: Network connection error (local cleanup still succeeds)
  /// - [ServerFailure]: Server error during logout (local cleanup still succeeds)
  Future<Either<Failure, void>> logout();

  /// Get current session from local storage
  ///
  /// Returns cached session if available and valid.
  /// Returns null if no session exists or session is expired.
  ///
  /// Possible failures:
  /// - [CacheFailure]: Error reading from local storage
  /// - [SecureStorageFailure]: Error reading from secure storage
  Future<Either<Failure, APISession?>> getCurrentSession();

  /// Get current user account from local storage
  ///
  /// Returns cached user account if available.
  /// Returns null if no user data exists.
  ///
  /// Possible failures:
  /// - [CacheFailure]: Error reading from local storage
  Future<Either<Failure, UserAccount?>> getCurrentUser();

  /// Save session to local storage
  ///
  /// Persists session tokens securely (keychain/keystore on mobile,
  /// encrypted IndexedDB on web).
  ///
  /// Possible failures:
  /// - [SecureStorageFailure]: Error writing to secure storage
  Future<Either<Failure, void>> saveSession(APISession session);

  /// Save user account to local storage
  ///
  /// Persists user account data to local cache.
  ///
  /// Possible failures:
  /// - [CacheFailure]: Error writing to local storage
  Future<Either<Failure, void>> saveUser(UserAccount user);

  /// Clear local session data
  ///
  /// Removes all authentication tokens and user data from local storage.
  ///
  /// Possible failures:
  /// - [CacheFailure]: Error clearing local storage
  /// - [SecureStorageFailure]: Error clearing secure storage
  Future<Either<Failure, void>> clearLocalSession();

  /// Check if current session is valid
  ///
  /// Returns true if session exists and access token is not expired.
  /// Returns false otherwise.
  Future<bool> isSessionValid();

  /// Check if session is expiring soon (within 5 minutes)
  ///
  /// Returns true if session exists but will expire within 5 minutes.
  /// Useful for triggering proactive token refresh.
  Future<bool> isSessionExpiringSoon();
}
