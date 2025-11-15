/// Base Repository Pattern for Harvia MSGA
///
/// Provides common repository functionality for offline-first data access
/// with error handling and caching
library;

import 'package:dartz/dartz.dart';

import '../error/failures.dart';
import '../utils/logger.dart';

/// Base repository with offline-first strategy
///
/// Implements common patterns for data fetching, caching, and error handling
abstract class BaseRepository {
  /// Execute operation with error handling
  ///
  /// Wraps repository operations in try-catch and converts exceptions to Failures
  ///
  /// Returns `Either<Failure, T>` for functional error handling
  Future<Either<Failure, T>> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      if (operationName != null) {
        AppLogger.d('Executing: $operationName');
      }

      final result = await operation();

      if (operationName != null) {
        AppLogger.d('Success: $operationName');
      }

      return Right(result);
    } on Failure catch (failure) {
      if (operationName != null) {
        AppLogger.w('Failure in $operationName: ${failure.userMessage}');
      }
      return Left(failure);
    } catch (error, stackTrace) {
      AppLogger.e(
        'Unexpected error in ${operationName ?? "operation"}',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure('Unexpected error: $error', error));
    }
  }

  /// Fetch data with cache-first strategy
  ///
  /// 1. Try to get from cache
  /// 2. If cache miss or expired, fetch from remote
  /// 3. Update cache with remote data
  /// 4. Return data or failure
  Future<Either<Failure, T>> fetchWithCache<T>({
    required Future<T?> Function() getFromCache,
    required Future<T> Function() getFromRemote,
    required Future<void> Function(T data) saveToCache,
    required bool Function(T? cached)? isCacheValid,
    String? operationName,
  }) async {
    try {
      // Try cache first
      final cached = await getFromCache();

      if (cached != null && (isCacheValid == null || isCacheValid(cached))) {
        AppLogger.cache('Read', operationName ?? 'data', hit: true);
        return Right(cached);
      }

      AppLogger.cache('Read', operationName ?? 'data', hit: false);

      // Cache miss or invalid - fetch from remote
      final remote = await getFromRemote();

      // Update cache
      await saveToCache(remote);

      AppLogger.cache('Write', operationName ?? 'data');

      return Right(remote);
    } on Failure catch (failure) {
      AppLogger.w('Fetch failed: ${failure.userMessage}');
      return Left(failure);
    } catch (error, stackTrace) {
      AppLogger.e(
        'Unexpected error in fetchWithCache',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure('Failed to fetch data: $error', error));
    }
  }

  /// Fetch data with network-first strategy
  ///
  /// 1. Try to fetch from remote
  /// 2. If network fails, fallback to cache
  /// 3. Return data or failure
  Future<Either<Failure, T>> fetchNetworkFirst<T>({
    required Future<T> Function() getFromRemote,
    required Future<T?> Function() getFromCache,
    required Future<void> Function(T data) saveToCache,
    String? operationName,
  }) async {
    try {
      // Try remote first
      try {
        final remote = await getFromRemote();

        // Update cache
        await saveToCache(remote);

        return Right(remote);
      } on NetworkFailure catch (_) {
        // Network failed - try cache
        AppLogger.w('Network unavailable, using cache');

        final cached = await getFromCache();

        if (cached != null) {
          AppLogger.cache('Read', operationName ?? 'data', hit: true);
          return Right(cached);
        }

        // No cache available
        return const Left(
          NetworkFailure('No internet connection and no cached data available'),
        );
      }
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error, stackTrace) {
      AppLogger.e(
        'Unexpected error in fetchNetworkFirst',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure('Failed to fetch data: $error', error));
    }
  }

  /// Execute mutation with optimistic update
  ///
  /// 1. Apply optimistic update to cache
  /// 2. Execute remote mutation
  /// 3. On success: keep optimistic update
  /// 4. On failure: rollback cache and return error
  Future<Either<Failure, T>> executeWithOptimisticUpdate<T>({
    required Future<void> Function() applyOptimisticUpdate,
    required Future<T> Function() executeMutation,
    required Future<void> Function() rollback,
    String? operationName,
  }) async {
    try {
      // Apply optimistic update
      await applyOptimisticUpdate();

      AppLogger.d(
        'Applied optimistic update for ${operationName ?? "mutation"}',
      );

      try {
        // Execute mutation
        final result = await executeMutation();

        AppLogger.i('Mutation successful: ${operationName ?? "operation"}');

        return Right(result);
      } catch (error) {
        // Mutation failed - rollback
        AppLogger.w('Mutation failed, rolling back optimistic update');

        await rollback();

        if (error is Failure) {
          return Left(error);
        }

        return Left(UnknownFailure('Mutation failed: $error', error));
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'Error in optimistic update',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure('Failed to execute mutation: $error', error));
    }
  }

  /// Queue operation for offline execution
  ///
  /// Useful for commands that should be executed when network is available
  Future<Either<Failure, void>> queueForOffline({
    required Future<void> Function() addToQueue,
    String? operationName,
  }) async {
    try {
      await addToQueue();

      AppLogger.i(
        'Queued for offline execution: ${operationName ?? "operation"}',
      );

      return const Right(null);
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to queue operation',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        CacheFailure('Failed to queue operation: $error', CacheOperation.write),
      );
    }
  }
}
