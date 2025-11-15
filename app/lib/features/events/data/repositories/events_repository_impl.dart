/// Events repository implementation
///
/// Implements offline-first event management with cache-first strategy
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_local_datasource.dart';
import '../datasources/events_remote_datasource.dart';
import '../models/event_dto.dart';

/// Events repository implementation
///
/// Handles event data operations with cache-first offline strategy
class EventsRepositoryImpl implements EventsRepository {
  final EventsRemoteDataSource remoteDataSource;
  final EventsLocalDataSource localDataSource;

  EventsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Event>>> getEvents({
    String? deviceId,
    List<EventType>? types,
    List<Severity>? severities,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.d(
        'Fetching events with filters: '
        'deviceId=$deviceId, types=$types, severities=$severities, '
        'limit=$limit, offset=$offset',
      );

      // Convert enum types to strings for GraphQL
      final typeStrings = types
          ?.map((t) => t.toString().split('.').last.toUpperCase())
          .toList();
      final severityStrings = severities
          ?.map((s) => s.toString().split('.').last.toUpperCase())
          .toList();

      // Try to fetch from remote first (network-first for events)
      try {
        final remoteDtos = await remoteDataSource.listEvents(
          deviceId: deviceId,
          types: typeStrings,
          severities: severityStrings,
          startDate: startDate?.toIso8601String(),
          endDate: endDate?.toIso8601String(),
          limit: limit,
          offset: offset,
        );

        AppLogger.i('Fetched ${remoteDtos.length} events from remote');

        // Cache the fetched events
        if (remoteDtos.isNotEmpty) {
          await localDataSource.cacheEvents(remoteDtos);
        }

        // Convert DTOs to entities
        final events = remoteDtos.map((dto) => dto.toEntity()).toList();
        return Right(events);
      } catch (e) {
        AppLogger.w('Remote fetch failed, falling back to cache: $e');

        // Fall back to cached events on network failure
        final cachedDtos = await localDataSource.getCachedEvents(
          deviceId: deviceId,
          limit: limit ?? 1000,
        );

        AppLogger.i('Returned ${cachedDtos.length} cached events');

        // Convert DTOs to entities
        final events = cachedDtos.map((dto) => dto.toEntity()).toList();
        return Right(events);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching events', error: e, stackTrace: stackTrace);
      return Left(CacheFailure('Failed to fetch events: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, Event>> subscribeToEvents({String? deviceId}) async* {
    try {
      AppLogger.i(
        'Subscribing to event stream for device: ${deviceId ?? "all"}',
      );

      await for (final eventDto in remoteDataSource.subscribeToEvents(
        deviceId: deviceId,
      )) {
        try {
          // Cache each received event
          await localDataSource.cacheEvents([eventDto]);

          // Convert DTO to entity
          final event = eventDto.toEntity();

          AppLogger.d('Received event: ${event.eventId} (${event.type})');
          yield Right(event);
        } catch (e) {
          AppLogger.w('Error caching event: $e');
          // Still yield the event even if caching fails
          final event = eventDto.toEntity();
          yield Right(event);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error in event subscription',
        error: e,
        stackTrace: stackTrace,
      );
      yield Left(NetworkFailure('Event subscription failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Event>> acknowledgeEvent(String eventId) async {
    try {
      AppLogger.d('Acknowledging event: $eventId');

      // Acknowledge remotely
      final acknowledgedDto = await remoteDataSource.acknowledgeEvent(eventId);

      // Update local cache
      await localDataSource.cacheEvents([acknowledgedDto]);

      // Convert DTO to entity
      final event = acknowledgedDto.toEntity();

      AppLogger.i('Event acknowledged: $eventId');
      return Right(event);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error acknowledging event',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ApiFailure('Failed to acknowledge event: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnacknowledgedCount({
    String? deviceId,
  }) async {
    try {
      AppLogger.d('Getting unacknowledged count for device: $deviceId');

      // Try remote first for accurate count
      try {
        final count = await remoteDataSource.getUnacknowledgedCount(
          deviceId: deviceId,
        );

        AppLogger.d('Unacknowledged count: $count');
        return Right(count);
      } catch (e) {
        AppLogger.w('Remote count failed, using cache: $e');

        // Fall back to cached count
        final cachedDtos = await localDataSource.getCachedEvents(
          deviceId: deviceId,
          limit: 1000,
        );

        final unacknowledgedCount = cachedDtos
            .where((dto) => dto.acknowledged != true)
            .length;

        return Right(unacknowledgedCount);
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error getting unacknowledged count',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to get count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearOldEvents({int daysToKeep = 30}) async {
    try {
      AppLogger.d('Clearing events older than $daysToKeep days');

      // Clear from local cache
      await localDataSource.clearOldEvents(daysToKeep: daysToKeep);

      AppLogger.i('Cleared old events successfully');
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error clearing old events',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to clear old events: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheEvents(List<Event> events) async {
    try {
      AppLogger.d('Caching ${events.length} events');

      // Convert entities to DTOs
      final dtos = events.map((e) => EventDTO.fromEntity(e)).toList();

      await localDataSource.cacheEvents(dtos);

      AppLogger.i('Events cached successfully');
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.e('Error caching events', error: e, stackTrace: stackTrace);
      return Left(CacheFailure('Failed to cache events: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getCachedEvents({
    String? deviceId,
    int? limit,
  }) async {
    try {
      AppLogger.d('Getting cached events: deviceId=$deviceId, limit=$limit');

      final cachedDtos = await localDataSource.getCachedEvents(
        deviceId: deviceId,
        limit: limit,
      );

      // Convert DTOs to entities
      final events = cachedDtos.map((dto) => dto.toEntity()).toList();

      AppLogger.i('Retrieved ${events.length} cached events');
      return Right(events);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error getting cached events',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to get cached events: ${e.toString()}'));
    }
  }
}
