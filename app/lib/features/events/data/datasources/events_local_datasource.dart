/// Events local data source (Hive cache)
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../models/event_dto.dart';

/// Events local data source
///
/// Implements ring buffer cache for events (max 1000 events)
class EventsLocalDataSource {
  static const String _boxName = 'events_cache';
  static const String _ackBoxName = 'pending_acknowledgments';
  static const int _maxEvents = 1000;

  Box<Map<dynamic, dynamic>>? _box;
  Box<String>? _ackBox;

  /// Initialize Hive boxes
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    } else {
      _box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    }

    if (!Hive.isBoxOpen(_ackBoxName)) {
      _ackBox = await Hive.openBox<String>(_ackBoxName);
    } else {
      _ackBox = Hive.box<String>(_ackBoxName);
    }
  }

  /// Cache events (ring buffer - keeps only latest 1000)
  Future<void> cacheEvents(List<EventDTO> events) async {
    await init();

    for (final event in events) {
      final key = event.eventId;
      await _box!.put(key, event.toJson());
    }

    // Enforce ring buffer limit
    if (_box!.length > _maxEvents) {
      final keysToDelete = _box!.keys.take(_box!.length - _maxEvents).toList();
      await _box!.deleteAll(keysToDelete);
    }
  }

  /// Get cached events
  Future<List<EventDTO>> getCachedEvents({String? deviceId, int? limit}) async {
    await init();

    final allEvents = _box!.values
        .map((json) => EventDTO.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    // Filter by device if specified
    var filteredEvents = deviceId != null
        ? allEvents.where((e) => e.deviceId == deviceId).toList()
        : allEvents;

    // Sort by timestamp (newest first)
    filteredEvents.sort((a, b) {
      final aTime = DateTime.parse(a.timestamp);
      final bTime = DateTime.parse(b.timestamp);
      return bTime.compareTo(aTime);
    });

    // Apply limit if specified
    if (limit != null && filteredEvents.length > limit) {
      filteredEvents = filteredEvents.take(limit).toList();
    }

    return filteredEvents;
  }

  /// Clear all cached events
  Future<void> clearCache() async {
    await init();
    await _box!.clear();
  }

  /// Clear events older than specified days
  Future<void> clearOldEvents({int daysToKeep = 30}) async {
    await init();

    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final keysToDelete = <String>[];

    for (final key in _box!.keys) {
      final json = _box!.get(key);
      if (json != null) {
        final event = EventDTO.fromJson(Map<String, dynamic>.from(json));
        final eventDate = DateTime.parse(event.timestamp);
        if (eventDate.isBefore(cutoffDate)) {
          keysToDelete.add(key.toString());
        }
      }
    }

    await _box!.deleteAll(keysToDelete);
  }

  /// Get event count
  Future<int> getEventCount({String? deviceId}) async {
    await init();

    if (deviceId == null) {
      return _box!.length;
    }

    return _box!.values
        .map((json) => EventDTO.fromJson(Map<String, dynamic>.from(json)))
        .where((e) => e.deviceId == deviceId)
        .length;
  }

  /// Add event acknowledgment to pending queue (for offline sync)
  Future<void> addPendingAcknowledgment(String eventId) async {
    await init();
    await _ackBox!.put(eventId, eventId);
  }

  /// Get pending acknowledgments
  Future<List<String>> getPendingAcknowledgments() async {
    await init();
    return _ackBox!.values.toList();
  }

  /// Remove acknowledgment from pending queue (after successful sync)
  Future<void> removePendingAcknowledgment(String eventId) async {
    await init();
    await _ackBox!.delete(eventId);
  }

  /// Clear all pending acknowledgments
  Future<void> clearPendingAcknowledgments() async {
    await init();
    await _ackBox!.clear();
  }
}
