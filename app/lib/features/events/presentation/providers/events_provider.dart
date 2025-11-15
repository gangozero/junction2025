/// Events stream provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/events_local_datasource.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';

/// Events repository provider
final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepositoryImpl(
    remoteDataSource: EventsRemoteDataSource.create(),
    localDataSource: EventsLocalDataSource(),
  );
});

/// Events stream provider
///
/// Provides real-time event updates via WebSocket subscription
final eventsStreamProvider = StreamProvider.family<Event, String?>((
  ref,
  deviceId,
) {
  final repository = ref.read(eventsRepositoryProvider);

  return repository.subscribeToEvents(deviceId: deviceId).asyncMap((result) {
    return result.fold(
      (failure) => throw Exception(failure.userMessage),
      (event) => event,
    );
  });
});

/// All events stream provider (subscribes to events for all devices)
final allEventsStreamProvider = StreamProvider<Event>((ref) {
  return ref.watch(eventsStreamProvider(null).stream);
});

/// Event list provider
///
/// Provides paginated list of events with filters
final eventsListProvider =
    FutureProvider.family<
      List<Event>,
      ({
        String? deviceId,
        List<EventType>? types,
        List<Severity>? severities,
        DateTime? startDate,
        DateTime? endDate,
        int? limit,
        int? offset,
      })
    >((ref, filters) async {
      final repository = ref.read(eventsRepositoryProvider);

      final result = await repository.getEvents(
        deviceId: filters.deviceId,
        types: filters.types,
        severities: filters.severities,
        startDate: filters.startDate,
        endDate: filters.endDate,
        limit: filters.limit,
        offset: filters.offset,
      );

      return result.fold(
        (failure) => throw Exception(failure.userMessage),
        (events) => events,
      );
    });

/// Unacknowledged events count provider
final unacknowledgedCountProvider = FutureProvider.family<int, String?>((
  ref,
  deviceId,
) async {
  final repository = ref.read(eventsRepositoryProvider);

  final result = await repository.getUnacknowledgedCount(deviceId: deviceId);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (count) => count,
  );
});

/// Cached events provider
///
/// Provides offline-accessible cached events
final cachedEventsProvider =
    FutureProvider.family<List<Event>, ({String? deviceId, int? limit})>((
      ref,
      params,
    ) async {
      final repository = ref.read(eventsRepositoryProvider);

      final result = await repository.getCachedEvents(
        deviceId: params.deviceId,
        limit: params.limit,
      );

      return result.fold(
        (failure) => throw Exception(failure.userMessage),
        (events) => events,
      );
    });

/// Event acknowledgment notifier
class EventAcknowledgmentNotifier extends StateNotifier<AsyncValue<Event?>> {
  final EventsRepository _repository;

  EventAcknowledgmentNotifier(this._repository) : super(const AsyncData(null));

  /// Acknowledge an event
  Future<void> acknowledgeEvent(String eventId) async {
    state = const AsyncLoading();

    final result = await _repository.acknowledgeEvent(eventId);

    state = result.fold(
      (failure) => AsyncError(failure.userMessage, StackTrace.current),
      (event) => AsyncData(event),
    );
  }
}

/// Event acknowledgment provider
final eventAcknowledgmentProvider =
    StateNotifierProvider<EventAcknowledgmentNotifier, AsyncValue<Event?>>((
      ref,
    ) {
      final repository = ref.read(eventsRepositoryProvider);
      return EventAcknowledgmentNotifier(repository);
    });

/// Event cache manager notifier
class EventCacheManagerNotifier extends StateNotifier<AsyncValue<void>> {
  final EventsRepository _repository;

  EventCacheManagerNotifier(this._repository) : super(const AsyncData(null));

  /// Clear old events from cache
  Future<void> clearOldEvents({int daysToKeep = 30}) async {
    state = const AsyncLoading();

    final result = await _repository.clearOldEvents(daysToKeep: daysToKeep);

    state = result.fold(
      (failure) => AsyncError(failure.userMessage, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  /// Cache events manually
  Future<void> cacheEvents(List<Event> events) async {
    state = const AsyncLoading();

    final result = await _repository.cacheEvents(events);

    state = result.fold(
      (failure) => AsyncError(failure.userMessage, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

/// Event cache manager provider
final eventCacheManagerProvider =
    StateNotifierProvider<EventCacheManagerNotifier, AsyncValue<void>>((ref) {
      final repository = ref.read(eventsRepositoryProvider);
      return EventCacheManagerNotifier(repository);
    });
