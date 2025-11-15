/// Event notification handler
///
/// Dispatches notifications for sauna events using platform-specific notification service
library;

import 'dart:async';

import '../../core/utils/logger.dart';
import '../../features/events/domain/entities/event.dart';
import 'notification_service.dart';

/// Event notification handler
///
/// Manages event notifications with smart filtering and priority handling
class EventNotificationHandler {
  static final EventNotificationHandler _instance =
      EventNotificationHandler._internal();
  factory EventNotificationHandler() => _instance;
  EventNotificationHandler._internal();

  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  StreamSubscription<Event>? _eventSubscription;

  /// Event types that trigger notifications (user configurable)
  Set<EventType> _enabledEventTypes = {
    EventType.error,
    EventType.warning,
    EventType.temperatureAlert,
    EventType.connectionChange,
    EventType.commandFailed,
  };

  /// Minimum severity level for notifications
  Severity _minimumSeverity = Severity.medium;

  /// Initialize event notification handler
  ///
  /// Sets up notification service and prepares for event listening
  Future<bool> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (_isInitialized) {
      AppLogger.i('Event notification handler already initialized');
      return true;
    }

    try {
      // Initialize underlying notification service
      final initialized = await _notificationService.initialize(
        onNotificationTap: onNotificationTap,
      );

      if (initialized) {
        _isInitialized = true;
        AppLogger.i('Event notification handler initialized successfully');
      } else {
        AppLogger.w(
          'Event notification handler initialized without permissions '
          '(will use in-app fallback)',
        );
        _isInitialized =
            true; // Still mark as initialized for in-app notifications
      }

      return true;
    } catch (e) {
      AppLogger.e('Failed to initialize event notification handler', error: e);
      return false;
    }
  }

  /// Start listening to event stream
  ///
  /// Subscribes to events and dispatches notifications based on configuration
  void startListening(Stream<Event> eventStream) {
    if (_eventSubscription != null) {
      AppLogger.w(
        'Already listening to events, stopping previous subscription',
      );
      _eventSubscription?.cancel();
    }

    _eventSubscription = eventStream.listen(
      (event) => _handleEvent(event),
      onError: (Object error) {
        AppLogger.e('Error in event stream', error: error);
      },
      cancelOnError: false,
    );

    AppLogger.i('Started listening to event stream for notifications');
  }

  /// Stop listening to events
  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    AppLogger.i('Stopped listening to event stream');
  }

  /// Handle incoming event and dispatch notification if needed
  void _handleEvent(Event event) {
    // Skip if event type is not enabled
    if (!_enabledEventTypes.contains(event.type)) {
      AppLogger.d(
        'Event type ${event.type} not enabled for notifications, skipping',
      );
      return;
    }

    // Skip if severity is below threshold
    if (_getSeverityLevel(event.severity) <
        _getSeverityLevel(_minimumSeverity)) {
      AppLogger.d(
        'Event severity ${event.severity} below threshold $_minimumSeverity, skipping',
      );
      return;
    }

    // Skip if already acknowledged
    if (event.acknowledged) {
      AppLogger.d('Event already acknowledged, skipping notification');
      return;
    }

    // Dispatch notification
    _dispatchNotification(event);
  }

  /// Dispatch notification for event
  void _dispatchNotification(Event event) {
    final notificationId = _getNotificationId(event);
    final priority = _mapSeverityToPriority(event.severity);

    AppLogger.i(
      'Dispatching notification for event: ${event.eventId} '
      '(type: ${event.type}, severity: ${event.severity})',
    );

    _notificationService.showNotification(
      id: notificationId,
      title: _buildNotificationTitle(event),
      body: _buildNotificationBody(event),
      payload: _buildNotificationPayload(event),
      priority: priority,
    );
  }

  /// Build notification title from event
  String _buildNotificationTitle(Event event) {
    // Use event title if available, otherwise generate from type
    if (event.title.isNotEmpty) {
      return event.title;
    }

    return switch (event.type) {
      EventType.error => 'Sauna Error',
      EventType.warning => 'Sauna Warning',
      EventType.temperatureAlert => 'Temperature Alert',
      EventType.connectionChange => 'Connection Status',
      EventType.commandFailed => 'Command Failed',
      EventType.stateChange => 'Sauna Status Changed',
      EventType.commandExecuted => 'Command Executed',
      EventType.info => 'Sauna Info',
      EventType.unknown => 'Sauna Notification',
    };
  }

  /// Build notification body from event
  String _buildNotificationBody(Event event) {
    return event.message;
  }

  /// Build notification payload for tap handling
  String _buildNotificationPayload(Event event) {
    // Encode event ID and device ID for navigation
    return 'event:${event.eventId}:${event.deviceId}';
  }

  /// Get unique notification ID from event
  ///
  /// Use consistent ID generation to allow notification updates
  int _getNotificationId(Event event) {
    // Use hash of event ID for consistent notification ID
    // This allows same event to update existing notification
    return event.eventId.hashCode.abs();
  }

  /// Map event severity to notification priority
  NotificationPriority _mapSeverityToPriority(Severity severity) {
    return switch (severity) {
      Severity.critical => NotificationPriority.high,
      Severity.high => NotificationPriority.high,
      Severity.medium => NotificationPriority.defaultPriority,
      Severity.low => NotificationPriority.low,
      Severity.info => NotificationPriority.low,
    };
  }

  /// Get numeric severity level for comparison
  int _getSeverityLevel(Severity severity) {
    return switch (severity) {
      Severity.critical => 5,
      Severity.high => 4,
      Severity.medium => 3,
      Severity.low => 2,
      Severity.info => 1,
    };
  }

  /// Update enabled event types for notifications
  void setEnabledEventTypes(Set<EventType> eventTypes) {
    _enabledEventTypes = eventTypes;
    AppLogger.i('Updated enabled event types: $_enabledEventTypes');
  }

  /// Update minimum severity level for notifications
  void setMinimumSeverity(Severity severity) {
    _minimumSeverity = severity;
    AppLogger.i('Updated minimum severity: $_minimumSeverity');
  }

  /// Get current enabled event types
  Set<EventType> get enabledEventTypes => Set.unmodifiable(_enabledEventTypes);

  /// Get current minimum severity
  Severity get minimumSeverity => _minimumSeverity;

  /// Check if notifications are available
  bool get hasNotificationPermission => _notificationService.hasPermission;

  /// Check if handler is initialized
  bool get isInitialized => _isInitialized;

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await _notificationService.requestPermissions();
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _isInitialized = false;
    AppLogger.i('Event notification handler disposed');
  }
}
