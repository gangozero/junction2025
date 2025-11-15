/// Auth local data source
library;

/// Authentication local data source
///
/// Handles secure storage of authentication tokens and user data.
/// Platform-specific: mobile (keychain/keystore), web (encrypted IndexedDB).

import 'dart:convert';

import '../../../../core/utils/logger.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../domain/entities/api_session.dart';
import '../../domain/entities/user_account.dart';

/// Authentication local data source
///
/// Provides secure storage for session tokens and user account data.
class AuthLocalDataSource {
  // Storage keys
  static const String _keyIdToken = 'auth_id_token';
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyTokenType = 'auth_token_type';
  static const String _keyExpiresAt = 'auth_expires_at';
  static const String _keyCreatedAt = 'auth_created_at';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserData = 'auth_user_data';

  AuthLocalDataSource();

  /// Save API session securely
  ///
  /// Stores session tokens in platform-native secure storage:
  /// - Mobile: iOS Keychain / Android Keystore
  /// - Web: Encrypted IndexedDB with session-derived key
  ///
  /// Throws exception on storage errors.
  Future<void> saveSession(APISession session) async {
    try {
      AppLogger.cache('save', 'api_session', hit: null);

      await Future.wait<void>([
        SecureStorageService.save(_keyIdToken, session.idToken),
        SecureStorageService.save(_keyAccessToken, session.accessToken),
        SecureStorageService.save(_keyRefreshToken, session.refreshToken),
        SecureStorageService.save(_keyTokenType, session.tokenType),
        SecureStorageService.save(
          _keyExpiresAt,
          session.expiresAt.toIso8601String(),
        ),
        SecureStorageService.save(
          _keyCreatedAt,
          session.createdAt.toIso8601String(),
        ),
        SecureStorageService.save(_keyUserId, session.userId),
      ]);

      AppLogger.auth('Session saved', details: {'userId': session.userId});
    } catch (e) {
      AppLogger.e('Failed to save session', error: e);
      rethrow;
    }
  }

  /// Get saved API session
  ///
  /// Retrieves session from secure storage.
  /// Returns null if no session exists.
  ///
  /// Throws exception on storage errors.
  Future<APISession?> getSession() async {
    try {
      AppLogger.cache('read', 'api_session', hit: null);

      final idToken = await SecureStorageService.get(_keyIdToken);
      if (idToken == null) {
        AppLogger.cache('read', 'api_session', hit: false);
        return null;
      }

      final accessToken = await SecureStorageService.get(_keyAccessToken);
      final refreshToken = await SecureStorageService.get(_keyRefreshToken);
      final tokenType = await SecureStorageService.get(_keyTokenType);
      final expiresAtStr = await SecureStorageService.get(_keyExpiresAt);
      final createdAtStr = await SecureStorageService.get(_keyCreatedAt);
      final userId = await SecureStorageService.get(_keyUserId);

      if (accessToken == null ||
          refreshToken == null ||
          expiresAtStr == null ||
          createdAtStr == null ||
          userId == null) {
        AppLogger.w('Incomplete session data, clearing session');
        await clearSession();
        return null;
      }

      final session = APISession(
        idToken: idToken,
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType ?? 'Bearer',
        expiresAt: DateTime.parse(expiresAtStr),
        createdAt: DateTime.parse(createdAtStr),
        userId: userId,
      );

      AppLogger.cache('read', 'api_session', hit: true);
      return session;
    } catch (e) {
      AppLogger.e('Failed to read session', error: e);
      rethrow;
    }
  }

  /// Save user account data
  ///
  /// Stores user account information in secure storage.
  ///
  /// Throws exception on storage errors.
  Future<void> saveUser(UserAccount user) async {
    try {
      AppLogger.cache('save', 'user_account', hit: null);

      final userData = jsonEncode({
        'userId': user.userId,
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': user.createdAt?.toIso8601String(),
        'lastLoginAt': user.lastLoginAt?.toIso8601String(),
        'linkedControllerIds': user.linkedControllerIds,
      });

      await SecureStorageService.save(_keyUserData, userData);

      AppLogger.auth('User account saved', details: {'userId': user.userId});
    } catch (e) {
      AppLogger.e('Failed to save user', error: e);
      rethrow;
    }
  }

  /// Get saved user account
  ///
  /// Retrieves user account from storage.
  /// Returns null if no user data exists.
  ///
  /// Throws exception on storage errors.
  Future<UserAccount?> getUser() async {
    try {
      AppLogger.cache('read', 'user_account', hit: null);

      final userDataStr = await SecureStorageService.get(_keyUserData);
      if (userDataStr == null) {
        AppLogger.cache('read', 'user_account', hit: false);
        return null;
      }

      final userData = jsonDecode(userDataStr) as Map<String, dynamic>;

      final user = UserAccount(
        userId: userData['userId'] as String,
        email: userData['email'] as String,
        displayName: userData['displayName'] as String?,
        createdAt: userData['createdAt'] != null
            ? DateTime.parse(userData['createdAt'] as String)
            : null,
        lastLoginAt: userData['lastLoginAt'] != null
            ? DateTime.parse(userData['lastLoginAt'] as String)
            : null,
        linkedControllerIds: (userData['linkedControllerIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      );

      AppLogger.cache('read', 'user_account', hit: true);
      return user;
    } catch (e) {
      AppLogger.e('Failed to read user', error: e);
      rethrow;
    }
  }

  /// Clear all session and user data
  ///
  /// Removes all authentication data from secure storage.
  ///
  /// Throws exception on storage errors.
  Future<void> clearSession() async {
    try {
      AppLogger.auth('Clearing session data');

      await Future.wait<void>([
        SecureStorageService.delete(_keyIdToken),
        SecureStorageService.delete(_keyAccessToken),
        SecureStorageService.delete(_keyRefreshToken),
        SecureStorageService.delete(_keyTokenType),
        SecureStorageService.delete(_keyExpiresAt),
        SecureStorageService.delete(_keyCreatedAt),
        SecureStorageService.delete(_keyUserId),
        SecureStorageService.delete(_keyUserData),
      ]);

      AppLogger.auth('Session data cleared');
    } catch (e) {
      AppLogger.e('Failed to clear session', error: e);
      rethrow;
    }
  }

  /// Check if session exists
  ///
  /// Returns true if access token is stored.
  Future<bool> hasSession() async {
    try {
      final accessToken = await SecureStorageService.get(_keyAccessToken);
      return accessToken != null;
    } catch (e) {
      AppLogger.e('Failed to check session', error: e);
      return false;
    }
  }
}
