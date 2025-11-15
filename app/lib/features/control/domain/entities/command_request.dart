/// Command request domain entity
library;

import 'package:equatable/equatable.dart';

/// Type of control command
enum CommandType {
  powerOn,
  powerOff,
  setTemperature,
  unknown;

  bool get isPowerCommand =>
      this == CommandType.powerOn || this == CommandType.powerOff;
}

/// Status of command execution
enum CommandStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled;

  bool get isTerminal =>
      this == CommandStatus.completed ||
      this == CommandStatus.failed ||
      this == CommandStatus.cancelled;
}

/// Command request entity
///
/// Represents a control command to be sent to a sauna controller
class CommandRequest extends Equatable {
  final String commandId;
  final String deviceId;
  final CommandType type;
  final Map<String, dynamic> parameters;
  final CommandStatus status;
  final DateTime requestedAt;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int retryCount;

  const CommandRequest({
    required this.commandId,
    required this.deviceId,
    required this.type,
    this.parameters = const {},
    this.status = CommandStatus.pending,
    required this.requestedAt,
    this.sentAt,
    this.completedAt,
    this.errorMessage,
    this.retryCount = 0,
  });

  @override
  List<Object?> get props => [
    commandId,
    deviceId,
    type,
    parameters,
    status,
    requestedAt,
    sentAt,
    completedAt,
    errorMessage,
    retryCount,
  ];

  /// Check if command can be retried
  bool get canRetry => status == CommandStatus.failed && retryCount < 3;

  /// Check if command is stale (older than 5 minutes without completion)
  bool get isStale {
    if (status.isTerminal) return false;
    return DateTime.now().difference(requestedAt) > const Duration(minutes: 5);
  }

  /// Check if command is in flight (sent but not completed)
  bool get isInFlight =>
      status == CommandStatus.inProgress && sentAt != null && !isStale;

  /// Duration since request
  Duration get age => DateTime.now().difference(requestedAt);

  /// Copy with updated fields
  CommandRequest copyWith({
    String? commandId,
    String? deviceId,
    CommandType? type,
    Map<String, dynamic>? parameters,
    CommandStatus? status,
    DateTime? requestedAt,
    DateTime? sentAt,
    DateTime? completedAt,
    String? errorMessage,
    int? retryCount,
  }) {
    return CommandRequest(
      commandId: commandId ?? this.commandId,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      sentAt: sentAt ?? this.sentAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Create a power ON command
  factory CommandRequest.powerOn({required String deviceId}) {
    return CommandRequest(
      commandId:
          '${deviceId}_power_on_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      type: CommandType.powerOn,
      requestedAt: DateTime.now(),
    );
  }

  /// Create a power OFF command
  factory CommandRequest.powerOff({required String deviceId}) {
    return CommandRequest(
      commandId:
          '${deviceId}_power_off_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      type: CommandType.powerOff,
      requestedAt: DateTime.now(),
    );
  }

  /// Create a set temperature command
  factory CommandRequest.setTemperature({
    required String deviceId,
    required double targetTemperature,
  }) {
    return CommandRequest(
      commandId:
          '${deviceId}_set_temp_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      type: CommandType.setTemperature,
      parameters: {'targetTemperature': targetTemperature},
      requestedAt: DateTime.now(),
    );
  }
}
