/// Authentication interceptor with automatic token refresh
library;

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/security.dart';
import '../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../features/auth/data/models/refresh_request.dart';

/// Auth interceptor for Dio
///
/// Adds access token to requests and automatically refreshes expired tokens
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  AuthInterceptor({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    try {
      final session = await _localDataSource.getSession();

      if (session == null) {
        AppLogger.w('No session found - skipping auth header');
        return handler.next(options);
      }

      // Validate token format before using
      if (!TokenSecurity.isValidJwtFormat(session.idToken)) {
        AppLogger.e('Invalid token format detected');
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'message': 'Invalid token format'},
            ),
          ),
        );
      }

      // Check if token is expiring soon
      if (session.isExpiringSoon && !session.isExpired) {
        AppLogger.i('Token expiring soon - triggering refresh');
        await _refreshToken();
        // Get updated session after refresh
        final updatedSession = await _localDataSource.getSession();
        if (updatedSession != null) {
          options.headers['Authorization'] = ApiConstants.getAuthHeader(
            updatedSession.idToken,
          );
        }
      } else if (session.isExpired) {
        AppLogger.w('Token expired - attempting refresh');
        await _refreshToken();
        // Get updated session after refresh
        final updatedSession = await _localDataSource.getSession();
        if (updatedSession != null) {
          options.headers['Authorization'] = ApiConstants.getAuthHeader(
            updatedSession.idToken,
          );
        } else {
          AppLogger.e('Token refresh failed - no session after refresh');
          return handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'message': 'Session expired'},
              ),
            ),
          );
        }
      } else {
        // Token is valid - add to headers
        options.headers['Authorization'] = ApiConstants.getAuthHeader(
          session.idToken,
        );
      }
    } catch (e) {
      AppLogger.e('Error in auth interceptor onRequest', error: e);
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors (unauthorized)
    if (err.response?.statusCode == 401 &&
        !_isPublicEndpoint(err.requestOptions.path)) {
      AppLogger.w('Received 401 - attempting token refresh');

      try {
        final session = await _localDataSource.getSession();

        if (session == null || session.refreshToken.isEmpty) {
          AppLogger.w('No refresh token available');
          await _localDataSource.clearSession();
          return handler.next(err);
        }

        // Attempt token refresh
        final success = await _refreshToken();

        if (success) {
          // Get new session
          final newSession = await _localDataSource.getSession();

          if (newSession != null) {
            // Retry original request with new token
            err.requestOptions.headers['Authorization'] =
                ApiConstants.getAuthHeader(newSession.accessToken);

            try {
              final retryDio = Dio();
              final response = await retryDio.fetch<dynamic>(
                err.requestOptions,
              );
              return handler.resolve(response);
            } catch (retryError) {
              AppLogger.e('Retry after refresh failed', error: retryError);
            }
          }
        }

        // Refresh failed - clear session
        AppLogger.w('Token refresh failed - clearing session');
        await _localDataSource.clearSession();
      } catch (e) {
        AppLogger.e('Error handling 401 in auth interceptor', error: e);
        await _localDataSource.clearSession();
      }
    }

    handler.next(err);
  }

  /// Refresh access token
  Future<bool> _refreshToken() async {
    try {
      final session = await _localDataSource.getSession();

      if (session == null || session.refreshToken.isEmpty) {
        AppLogger.w('Cannot refresh - no session or refresh token');
        return false;
      }

      AppLogger.i('Refreshing access token');

      final refreshRequest = RefreshRequest(refreshToken: session.refreshToken);

      final response = await _remoteDataSource.refreshToken(refreshRequest);

      // Save new tokens
      final newSession = session.copyWith(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: DateTime.now().add(Duration(seconds: response.expiresIn)),
      );

      await _localDataSource.saveSession(newSession);

      AppLogger.i('Token refresh successful');
      return true;
    } catch (e) {
      AppLogger.e('Token refresh failed', error: e);
      return false;
    }
  }

  /// Check if endpoint is public (doesn't require authentication)
  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      ApiConstants.authTokenEndpoint,
      ApiConstants.authRefreshEndpoint,
    ];

    return publicEndpoints.any((endpoint) => path.endsWith(endpoint));
  }
}
