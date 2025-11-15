/// Auth repository implementation
library;

/// Authentication repository implementation
///
/// Implements auth repository interface with token management,
/// offline support, and error handling.

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/api_session.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request.dart';
import '../models/refresh_request.dart';

/// Authentication repository implementation
///
/// Coordinates between remote API and local storage for authentication.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
       _localDataSource = localDataSource ?? AuthLocalDataSource();

  @override
  Future<Either<Failure, (APISession, UserAccount)>> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
  }) async {
    try {
      AppLogger.auth('Login attempt', details: {'email': email});

      final request = LoginRequest(
        email: email,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      final tokenResponse = await _remoteDataSource.login(request);
      final (session, user) = tokenResponse.toDomainEntities();

      // Save session and user to local storage
      await _localDataSource.saveSession(session);
      await _localDataSource.saveUser(user);

      AppLogger.auth('Login successful', details: {'userId': user.userId});

      return Right((session, user));
    } on DioException catch (e) {
      AppLogger.auth('Login failed', details: {'error': e.message});
      return Left(_handleDioException(e));
    } catch (e) {
      AppLogger.e('Unexpected login error', error: e);
      return Left(UnknownFailure('An unexpected error occurred during login'));
    }
  }

  @override
  Future<Either<Failure, APISession>> refreshToken({
    required String refreshToken,
    String? deviceId,
  }) async {
    try {
      AppLogger.auth('Token refresh attempt');

      final request = RefreshRequest(
        refreshToken: refreshToken,
        deviceId: deviceId,
      );

      final tokenResponse = await _remoteDataSource.refreshToken(request);
      final (session, _) = tokenResponse.toDomainEntities();

      // Save new session to local storage
      await _localDataSource.saveSession(session);

      AppLogger.auth('Token refresh successful');

      return Right(session);
    } on DioException catch (e) {
      AppLogger.auth('Token refresh failed', details: {'error': e.message});
      return Left(_handleDioException(e));
    } catch (e) {
      AppLogger.e('Unexpected token refresh error', error: e);
      return Left(
        UnknownFailure('An unexpected error occurred during token refresh'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> revokeToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      AppLogger.auth('Token revocation attempt');

      await _remoteDataSource.revokeToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      AppLogger.auth('Token revocation successful');

      return const Right(null);
    } on DioException catch (e) {
      AppLogger.auth('Token revocation failed', details: {'error': e.message});
      return Left(_handleDioException(e));
    } catch (e) {
      AppLogger.e('Unexpected token revocation error', error: e);
      return Left(
        UnknownFailure('An unexpected error occurred during token revocation'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      AppLogger.auth('Logout attempt');

      // Get current session for token revocation
      final session = await _localDataSource.getSession();

      // Revoke tokens on server if session exists
      if (session != null && session.isValid) {
        await _remoteDataSource.revokeToken(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      }

      // Clear local session data regardless of revocation result
      await _localDataSource.clearSession();

      AppLogger.auth('Logout successful');

      return const Right(null);
    } on DioException catch (e) {
      // Even if server revocation fails, clear local data
      AppLogger.w(
        'Token revocation failed, clearing local data anyway',
        error: e,
      );
      await _localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      AppLogger.e('Unexpected logout error', error: e);
      // Clear local data even on error
      try {
        await _localDataSource.clearSession();
      } catch (clearError) {
        AppLogger.e('Failed to clear local session', error: clearError);
      }
      return Left(UnknownFailure('An unexpected error occurred during logout'));
    }
  }

  @override
  Future<Either<Failure, APISession?>> getCurrentSession() async {
    try {
      final session = await _localDataSource.getSession();
      return Right(session);
    } catch (e) {
      AppLogger.e('Failed to get current session', error: e);
      return Left(
        SecureStorageFailure('Failed to retrieve session from storage'),
      );
    }
  }

  @override
  Future<Either<Failure, UserAccount?>> getCurrentUser() async {
    try {
      final user = await _localDataSource.getUser();
      return Right(user);
    } catch (e) {
      AppLogger.e('Failed to get current user', error: e);
      return Left(CacheFailure('Failed to retrieve user from storage'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSession(APISession session) async {
    try {
      await _localDataSource.saveSession(session);
      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to save session', error: e);
      return Left(SecureStorageFailure('Failed to save session to storage'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUser(UserAccount user) async {
    try {
      await _localDataSource.saveUser(user);
      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to save user', error: e);
      return Left(CacheFailure('Failed to save user to storage'));
    }
  }

  @override
  Future<Either<Failure, void>> clearLocalSession() async {
    try {
      await _localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to clear local session', error: e);
      return Left(SecureStorageFailure('Failed to clear session from storage'));
    }
  }

  @override
  Future<bool> isSessionValid() async {
    try {
      final session = await _localDataSource.getSession();
      return session != null && session.isValid;
    } catch (e) {
      AppLogger.e('Failed to check session validity', error: e);
      return false;
    }
  }

  @override
  Future<bool> isSessionExpiringSoon() async {
    try {
      final session = await _localDataSource.getSession();
      return session != null && session.isExpiringSoon;
    } catch (e) {
      AppLogger.e('Failed to check session expiry', error: e);
      return false;
    }
  }

  /// Handle Dio exceptions and convert to domain failures
  Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          'Connection timeout - please check your internet connection',
        );

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return AuthFailure('Invalid credentials or session expired');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerFailure('Server error - please try again later');
        }
        final message = exception.response?.data?['message'];
        return ApiFailure(message is String ? message : 'Request failed');

      case DioExceptionType.cancel:
        return NetworkFailure('Request was cancelled');

      case DioExceptionType.connectionError:
        return NetworkFailure(
          'No internet connection - please check your network',
        );

      case DioExceptionType.badCertificate:
        return NetworkFailure('SSL certificate error');

      case DioExceptionType.unknown:
        return NetworkFailure('Network error occurred');
    }
  }
}
