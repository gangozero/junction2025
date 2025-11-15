/// REST API Client for Harvia MSGA
///
/// Configures Dio HTTP client with interceptors for authentication,
/// logging, and error handling
library;

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/logger.dart';
import '../../storage/secure_storage_service.dart';

/// REST API client service
///
/// Manages HTTP requests with authentication and error handling
class RestApiClient {
  RestApiClient._();

  static Dio? _dio;

  /// Get Dio instance
  ///
  /// Initializes Dio on first access with interceptors
  static Dio getDio() {
    if (_dio != null) return _dio!;

    AppLogger.i('Initializing REST API client');

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.restBaseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectionTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          'Accept': ApiConstants.acceptJson,
        },
      ),
    );

    // Add interceptors
    _dio!.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);

    AppLogger.i('REST API client initialized');
    return _dio!;
  }

  /// Execute GET request
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final dio = getDio();
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Execute POST request
  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final dio = getDio();
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Execute PUT request
  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final dio = getDio();
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Execute DELETE request
  static Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final dio = getDio();
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors
  ///
  /// Converts DioException to appropriate Failure
  static Failure _handleDioError(DioException error) {
    AppLogger.e('REST API error', error: error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure('Request timed out');

      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == null) {
          return const ServerFailure('Invalid server response');
        }

        // Handle authentication errors
        if (statusCode == 401) {
          return const AuthFailure(
            'Unauthorized',
            AuthFailureReason.unauthorized,
          );
        }

        // Handle server errors
        if (statusCode >= 500) {
          return ServerFailure(
            data is Map ? data['message']?.toString() : null,
            statusCode,
          );
        }

        // Handle client errors
        return ApiFailure(
          data is Map ? data['message']?.toString() : null,
          statusCode,
          data is Map ? data['errors'] as Map<String, dynamic>? : null,
        );

      case DioExceptionType.cancel:
        return const ApiFailure('Request cancelled');

      case DioExceptionType.badCertificate:
        return const ServerFailure('SSL certificate error');

      case DioExceptionType.unknown:
        return UnknownFailure(error.message, error.error);
    }
  }

  /// Reset client
  static void reset() {
    AppLogger.i('Resetting REST API client');
    _dio?.close();
    _dio = null;
  }
}

/// Authentication interceptor
///
/// Adds access token to request headers
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = ApiConstants.getAuthHeader(token);
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors (token expired)
    if (err.response?.statusCode == 401) {
      AppLogger.w('Received 401 - token may be expired');

      // Try to refresh token
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken != null) {
        try {
          // Attempt token refresh
          final dio = Dio();
          final response = await dio.post<Map<String, dynamic>>(
            ApiConstants.getRestUrl(ApiConstants.authRefreshEndpoint),
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data?['access_token'] as String?;
            final newRefreshToken = response.data?['refresh_token'] as String?;

            if (newAccessToken != null) {
              await SecureStorageService.saveAccessToken(newAccessToken);

              if (newRefreshToken != null) {
                await SecureStorageService.saveRefreshToken(newRefreshToken);
              }

              // Retry original request with new token
              err.requestOptions.headers['Authorization'] =
                  ApiConstants.getAuthHeader(newAccessToken);

              final retryResponse = await dio.fetch<dynamic>(
                err.requestOptions,
              );
              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          AppLogger.e('Token refresh failed', error: e);
          // Clear tokens and let error propagate
          await SecureStorageService.clearAuthData();
        }
      }
    }

    handler.next(err);
  }
}

/// Logging interceptor
///
/// Logs request and response details
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.api(
      options.method,
      options.uri.toString(),
      headers: options.headers,
      body: options.data,
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.apiResponse(
      response.statusCode ?? 0,
      response.requestOptions.uri.toString(),
      body: response.data,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.apiResponse(
      err.response?.statusCode ?? 0,
      err.requestOptions.uri.toString(),
      body: err.response?.data,
    );
    handler.next(err);
  }
}

/// Error interceptor
///
/// Handles retry logic for failed requests
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on network errors or 5xx errors
    final shouldRetry =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);

    if (shouldRetry) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

      if (retryCount < ApiConstants.maxRetryAttempts) {
        AppLogger.w('Retrying request (attempt ${retryCount + 1})');

        // Exponential backoff
        final delay = Duration(
          milliseconds:
              (ApiConstants.retryDelayMs *
                      (ApiConstants.retryDelayMultiplier * retryCount))
                  .toInt(),
        );

        await Future<void>.delayed(delay);

        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final response = await Dio().fetch<dynamic>(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // Retry failed, continue with original error
        }
      }
    }

    handler.next(err);
  }
}
