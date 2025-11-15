/// Events repository interface
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/event.dart';

/// Events repository interface
///
/// Defines contract for event data operations
abstract class EventsRepository {
  /// Get events with optional filters
  ///
  /// [deviceId] - Filter by specific device
  /// [types] - Filter by event types
  /// [severities] - Filter by severity levels
  /// [startDate] - Filter events after this date
  /// [endDate] - Filter events before this date
  /// [limit] - Maximum number of events to return
  /// [offset] - Pagination offset
  Future<Either<Failure, List<Event>>> getEvents({
    String? deviceId,
    List<EventType>? types,
    List<Severity>? severities,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Subscribe to real-time event stream
  ///
  /// Returns a stream of events as they occur
  /// [deviceId] - Subscribe to specific device (null for all devices)
  Stream<Either<Failure, Event>> subscribeToEvents({String? deviceId});

  /// Acknowledge an event
  Future<Either<Failure, Event>> acknowledgeEvent(String eventId);

  /// Get unacknowledged events count
  Future<Either<Failure, int>> getUnacknowledgedCount({String? deviceId});

  /// Clear acknowledged events older than specified days
  Future<Either<Failure, void>> clearOldEvents({int daysToKeep = 30});

  /// Cache events locally
  Future<Either<Failure, void>> cacheEvents(List<Event> events);

  /// Get cached events (for offline mode)
  Future<Either<Failure, List<Event>>> getCachedEvents({
    String? deviceId,
    int? limit,
  });
}
