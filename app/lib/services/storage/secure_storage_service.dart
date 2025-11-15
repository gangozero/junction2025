/// Secure Storage Service for Harvia MSGA
///
/// Platform-specific secure storage wrapper:
/// - Mobile: flutter_secure_storage (Keychain/Keystore)
/// - Web: Encrypted IndexedDB via flutter_secure_storage_web
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/api_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/platform_utils.dart';

/// Secure storage service for sensitive data
///
/// Handles platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (Android Keystore)
/// - Web: Encrypted IndexedDB
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    webOptions: WebOptions(
      dbName: 'harvia_msga_secure',
      publicKey: 'harvia_msga_public_key',
    ),
  );

  /// Save access token
  static Future<void> saveAccessToken(String token) async {
    try {
      AppLogger.d('Saving access token to ${PlatformUtils.storageType}');
      await _storage.write(key: ApiConstants.accessTokenKey, value: token);
      AppLogger.i('Access token saved');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to save access token',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to save access token: $e');
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: ApiConstants.accessTokenKey);
      AppLogger.d(
        'Access token retrieved: ${token != null ? '[PRESENT]' : '[ABSENT]'}',
      );
      return token;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to get access token',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to retrieve access token: $e');
    }
  }

  /// Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    try {
      AppLogger.d('Saving refresh token to ${PlatformUtils.storageType}');
      await _storage.write(key: ApiConstants.refreshTokenKey, value: token);
      AppLogger.i('Refresh token saved');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to save refresh token',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to save refresh token: $e');
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: ApiConstants.refreshTokenKey);
      AppLogger.d(
        'Refresh token retrieved: ${token != null ? '[PRESENT]' : '[ABSENT]'}',
      );
      return token;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to get refresh token',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to retrieve refresh token: $e');
    }
  }

  /// Save user ID
  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: ApiConstants.userIdKey, value: userId);
      AppLogger.i('User ID saved: $userId');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to save user ID', error: e, stackTrace: stackTrace);
      throw SecureStorageFailure('Failed to save user ID: $e');
    }
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: ApiConstants.userIdKey);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get user ID', error: e, stackTrace: stackTrace);
      throw SecureStorageFailure('Failed to retrieve user ID: $e');
    }
  }

  /// Save session encryption key (for web IndexedDB)
  static Future<void> saveSessionKey(String key) async {
    try {
      await _storage.write(key: ApiConstants.sessionKey, value: key);
      AppLogger.d('Session key saved');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to save session key',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to save session key: $e');
    }
  }

  /// Get session encryption key (for web IndexedDB)
  static Future<String?> getSessionKey() async {
    try {
      return await _storage.read(key: ApiConstants.sessionKey);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to get session key',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to retrieve session key: $e');
    }
  }

  /// Save custom key-value pair
  static Future<void> save(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.d('Saved to secure storage: $key');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to save $key', error: e, stackTrace: stackTrace);
      throw SecureStorageFailure('Failed to save data: $e');
    }
  }

  /// Get value by key
  static Future<String?> get(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get $key', error: e, stackTrace: stackTrace);
      throw SecureStorageFailure('Failed to retrieve data: $e');
    }
  }

  /// Delete specific key
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.d('Deleted from secure storage: $key');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to delete $key', error: e, stackTrace: stackTrace);
      throw SecureStorageFailure('Failed to delete data: $e');
    }
  }

  /// Clear all authentication data
  static Future<void> clearAuthData() async {
    try {
      AppLogger.w('Clearing all authentication data');

      await Future.wait([
        delete(ApiConstants.accessTokenKey),
        delete(ApiConstants.refreshTokenKey),
        delete(ApiConstants.userIdKey),
        delete(ApiConstants.sessionKey),
      ]);

      AppLogger.i('Authentication data cleared');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to clear auth data',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to clear authentication data: $e');
    }
  }

  /// Clear all secure storage
  static Future<void> clearAll() async {
    try {
      AppLogger.w('Clearing all secure storage');
      await _storage.deleteAll();
      AppLogger.i('All secure storage cleared');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to clear all secure storage',
        error: e,
        stackTrace: stackTrace,
      );
      throw SecureStorageFailure('Failed to clear secure storage: $e');
    }
  }

  /// Check if access token exists
  static Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if refresh token exists
  static Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if user is authenticated (has valid tokens)
  static Future<bool> isAuthenticated() async {
    return await hasAccessToken() && await hasRefreshToken();
  }
}
