/// Event data transfer object
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/event.dart';

/// Event DTO for GraphQL mapping
class EventDTO extends Equatable {
  final String eventId;
  final String deviceId;
  final String type;
  final String severity;
  final String title;
  final String message;
  final String timestamp;
  final Map<String, dynamic>? metadata;
  final bool? acknowledged;
  final String? acknowledgedAt;

  const EventDTO({
    required this.eventId,
    required this.deviceId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.metadata,
    this.acknowledged,
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

  /// Convert from GraphQL JSON
  factory EventDTO.fromJson(Map<String, dynamic> json) {
    return EventDTO(
      eventId: json['eventId'] as String,
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      severity: json['severity'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: json['timestamp'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      acknowledged: json['acknowledged'] as bool?,
      acknowledgedAt: json['acknowledgedAt'] as String?,
    );
  }

  /// Convert to GraphQL JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'deviceId': deviceId,
      'type': type,
      'severity': severity,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (acknowledgedAt != null) 'acknowledgedAt': acknowledgedAt,
    };
  }

  /// Convert DTO to domain entity
  Event toEntity() {
    return Event(
      eventId: eventId,
      deviceId: deviceId,
      type: _parseEventType(type),
      severity: _parseSeverity(severity),
      title: title,
      message: message,
      timestamp: DateTime.parse(timestamp),
      metadata: metadata ?? const {},
      acknowledged: acknowledged ?? false,
      acknowledgedAt: acknowledgedAt != null
          ? DateTime.parse(acknowledgedAt!)
          : null,
    );
  }

  /// Create DTO from domain entity
  factory EventDTO.fromEntity(Event event) {
    return EventDTO(
      eventId: event.eventId,
      deviceId: event.deviceId,
      type: _eventTypeToString(event.type),
      severity: _severityToString(event.severity),
      title: event.title,
      message: event.message,
      timestamp: event.timestamp.toIso8601String(),
      metadata: event.metadata.isNotEmpty ? event.metadata : null,
      acknowledged: event.acknowledged,
      acknowledgedAt: event.acknowledgedAt?.toIso8601String(),
    );
  }

  /// Parse EventType from string
  static EventType _parseEventType(String type) {
    return switch (type.toUpperCase()) {
      'ERROR' => EventType.error,
      'WARNING' => EventType.warning,
      'INFO' => EventType.info,
      'STATE_CHANGE' => EventType.stateChange,
      'COMMAND_EXECUTED' => EventType.commandExecuted,
      'COMMAND_FAILED' => EventType.commandFailed,
      'CONNECTION_CHANGE' => EventType.connectionChange,
      'TEMPERATURE_ALERT' => EventType.temperatureAlert,
      _ => EventType.unknown,
    };
  }

  /// Convert EventType to string
  static String _eventTypeToString(EventType type) {
    return switch (type) {
      EventType.error => 'ERROR',
      EventType.warning => 'WARNING',
      EventType.info => 'INFO',
      EventType.stateChange => 'STATE_CHANGE',
      EventType.commandExecuted => 'COMMAND_EXECUTED',
      EventType.commandFailed => 'COMMAND_FAILED',
      EventType.connectionChange => 'CONNECTION_CHANGE',
      EventType.temperatureAlert => 'TEMPERATURE_ALERT',
      EventType.unknown => 'UNKNOWN',
    };
  }

  /// Parse Severity from string
  static Severity _parseSeverity(String severity) {
    return switch (severity.toUpperCase()) {
      'CRITICAL' => Severity.critical,
      'HIGH' => Severity.high,
      'MEDIUM' => Severity.medium,
      'LOW' => Severity.low,
      'INFO' => Severity.info,
      _ => Severity.info,
    };
  }

  /// Convert Severity to string
  static String _severityToString(Severity severity) {
    return switch (severity) {
      Severity.critical => 'CRITICAL',
      Severity.high => 'HIGH',
      Severity.medium => 'MEDIUM',
      Severity.low => 'LOW',
      Severity.info => 'INFO',
    };
  }
}
