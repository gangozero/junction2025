/// Auth remote data source
library;

/// Authentication remote data source
///
/// Handles authentication API calls to the vendor's REST API.
/// Manages token acquisition, refresh, and revocation.

import 'package:dio/dio.dart';

import '../../../../core/utils/logger.dart';
import '../../../../services/api/rest/rest_client.dart';
import '../models/login_request.dart';
import '../models/refresh_request.dart';
import '../models/token_response.dart';

/// Authentication remote data source
///
/// Provides methods for interacting with the authentication API.
/// Uses the REST API generics service for auth operations.
class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource({Dio? dio})
    : _dio = dio ?? RestApiClient.getDio(RestApiService.generics);

  /// Login with email and password
  ///
  /// POST /auth/token
  /// Returns [TokenResponse] with access token, refresh token, and user data.
  ///
  /// Throws [DioException] on network or API errors.
  Future<TokenResponse> login(LoginRequest request) async {
    try {
      AppLogger.api('POST /auth/token', 'Login request for ${request.email}');

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/token',
        data: request.toJson(),
      );

      AppLogger.api(
        'POST /auth/token',
        'Login successful for ${request.email}',
      );

      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.api('POST /auth/token', 'Login failed: ${e.message}');
      rethrow;
    }
  }

  /// Refresh access token
  ///
  /// POST /auth/refresh
  /// Returns [TokenResponse] with new access token.
  ///
  /// Throws [DioException] on network or API errors.
  Future<TokenResponse> refreshToken(RefreshRequest request) async {
    try {
      AppLogger.api('POST /auth/refresh', 'Token refresh request');

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: request.toJson(),
      );

      AppLogger.api('POST /auth/refresh', 'Token refresh successful');

      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.api('POST /auth/refresh', 'Token refresh failed: ${e.message}');
      rethrow;
    }
  }

  /// Revoke authentication tokens
  ///
  /// POST /auth/revoke
  /// Invalidates access and refresh tokens on the server.
  ///
  /// Throws [DioException] on network or API errors.
  Future<void> revokeToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      AppLogger.api('POST /auth/revoke', 'Token revocation request');

      await _dio.post<void>(
        '/auth/revoke',
        data: {'access_token': accessToken, 'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      AppLogger.api('POST /auth/revoke', 'Token revocation successful');
    } on DioException catch (e) {
      AppLogger.api(
        'POST /auth/revoke',
        'Token revocation failed: ${e.message}',
      );
      rethrow;
    }
  }

  /// Verify token validity
  ///
  /// GET /auth/verify
  /// Checks if the provided access token is still valid.
  ///
  /// Returns true if token is valid, false otherwise.
  Future<bool> verifyToken(String accessToken) async {
    try {
      AppLogger.api('GET /auth/verify', 'Token verification request');

      await _dio.get<void>(
        '/auth/verify',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      AppLogger.api('GET /auth/verify', 'Token is valid');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        AppLogger.api('GET /auth/verify', 'Token is invalid or expired');
        return false;
      }

      AppLogger.api(
        'GET /auth/verify',
        'Token verification failed: ${e.message}',
      );
      rethrow;
    }
  }
}
