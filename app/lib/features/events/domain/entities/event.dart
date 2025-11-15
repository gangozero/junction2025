/// Event domain entity
library;

import 'package:equatable/equatable.dart';

/// Type of event
enum EventType {
  error,
  warning,
  info,
  stateChange,
  commandExecuted,
  commandFailed,
  connectionChange,
  temperatureAlert,
  unknown;

  /// Check if event type requires user attention
  bool get requiresAttention =>
      this == EventType.error ||
      this == EventType.warning ||
      this == EventType.commandFailed;
}

/// Severity level of event
enum Severity {
  critical, // System failure, immediate action required
  high, // Important issues that need attention
  medium, // Notable events, should be reviewed
  low, // Informational, no action needed
  info; // General information

  /// Check if severity requires notification
  bool get requiresNotification =>
      this == Severity.critical || this == Severity.high;
}

/// Event entity
///
/// Represents a system event (error, warning, state change, etc.)
class Event extends Equatable {
  final String eventId;
  final String deviceId;
  final EventType type;
  final Severity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final bool acknowledged;
  final DateTime? acknowledgedAt;

  const Event({
    required this.eventId,
    required this.deviceId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
    this.acknowledged = false,
    this.acknowledgedAt,
  });

  @override
  List<Object?> get props => [
    eventId,
    deviceId,
    type,
    severity,
    title,
    message,
    timestamp,
    metadata,
    acknowledged,
    acknowledgedAt,
  ];

  /// Check if event is recent (within last hour)
  bool get isRecent =>
      DateTime.now().difference(timestamp) < const Duration(hours: 1);

  /// Check if event needs user action
  bool get needsAction => !acknowledged && type.requiresAttention;

  /// Get severity color for UI
  String get severityColor {
    return switch (severity) {
      Severity.critical => '#D32F2F', // Red
      Severity.high => '#F57C00', // Orange
      Severity.medium => '#FBC02D', // Yellow
      Severity.low => '#1976D2', // Blue
      Severity.info => '#757575', // Grey
    };
  }

  /// Get event icon
  String get iconName {
    return switch (type) {
      EventType.error => 'error',
      EventType.warning => 'warning',
      EventType.info => 'info',
      EventType.stateChange => 'swap_horiz',
      EventType.commandExecuted => 'check_circle',
      EventType.commandFailed => 'cancel',
      EventType.connectionChange => 'wifi',
      EventType.temperatureAlert => 'thermostat',
      EventType.unknown => 'help_outline',
    };
  }

  /// Copy with updated fields
  Event copyWith({
    String? eventId,
    String? deviceId,
    EventType? type,
    Severity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? acknowledged,
    DateTime? acknowledgedAt,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  /// Acknowledge this event
  Event acknowledge() {
    return copyWith(acknowledged: true, acknowledgedAt: DateTime.now());
  }

  /// Create empty event for testing
  factory Event.empty() {
    return Event(
      eventId: '',
      deviceId: '',
      type: EventType.info,
      severity: Severity.info,
      title: '',
      message: '',
      timestamp: DateTime.now(),
    );
  }
}
