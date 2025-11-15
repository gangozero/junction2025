/// Temperature command data transfer object
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/command_request.dart';

/// Temperature command request DTO
///
/// Used to serialize temperature adjustment commands for GraphQL
class TemperatureCommandDTO extends Equatable {
  final String deviceId;
  final double targetTemperature;
  final String? requestId;

  const TemperatureCommandDTO({
    required this.deviceId,
    required this.targetTemperature,
    this.requestId,
  });

  @override
  List<Object?> get props => [deviceId, targetTemperature, requestId];

  /// Convert to GraphQL variables
  Map<String, dynamic> toGraphQLVariables() {
    return {
      'deviceId': deviceId,
      'targetTemperature': targetTemperature,
      if (requestId != null) 'requestId': requestId,
    };
  }

  /// Create from CommandRequest entity
  factory TemperatureCommandDTO.fromEntity(CommandRequest command) {
    if (command.type != CommandType.setTemperature) {
      throw ArgumentError('CommandRequest must be of type setTemperature');
    }

    final targetTemp = command.parameters['targetTemperature'];
    if (targetTemp == null) {
      throw ArgumentError(
        'CommandRequest parameters must include targetTemperature',
      );
    }

    return TemperatureCommandDTO(
      deviceId: command.deviceId,
      targetTemperature: (targetTemp as num).toDouble(),
      requestId: command.commandId,
    );
  }

  /// Create entity from DTO (for response handling)
  CommandRequest toEntity({
    required CommandStatus status,
    required DateTime requestedAt,
    DateTime? sentAt,
    DateTime? completedAt,
    String? errorMessage,
    int retryCount = 0,
  }) {
    return CommandRequest(
      commandId: requestId ?? '',
      deviceId: deviceId,
      type: CommandType.setTemperature,
      parameters: {'targetTemperature': targetTemperature},
      status: status,
      requestedAt: requestedAt,
      sentAt: sentAt,
      completedAt: completedAt,
      errorMessage: errorMessage,
      retryCount: retryCount,
    );
  }

  /// Create from JSON
  factory TemperatureCommandDTO.fromJson(Map<String, dynamic> json) {
    return TemperatureCommandDTO(
      deviceId: json['deviceId'] as String,
      targetTemperature: (json['targetTemperature'] as num).toDouble(),
      requestId: json['requestId'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'targetTemperature': targetTemperature,
      if (requestId != null) 'requestId': requestId,
    };
  }
}
