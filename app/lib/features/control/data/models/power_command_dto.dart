/// Power command DTO (Data Transfer Object)
library;

import '../../domain/entities/command_request.dart';

/// Power command DTO for GraphQL mutations
class PowerCommandDto {
  final String deviceId;
  final bool powerOn;

  const PowerCommandDto({required this.deviceId, required this.powerOn});

  /// Convert from domain entity
  factory PowerCommandDto.fromEntity(CommandRequest command) {
    assert(command.type.isPowerCommand, 'Command must be a power command');

    return PowerCommandDto(
      deviceId: command.deviceId,
      powerOn: command.type == CommandType.powerOn,
    );
  }

  /// Convert to GraphQL variables
  Map<String, dynamic> toGraphQL() {
    return {'deviceId': deviceId, 'powerOn': powerOn};
  }

  /// Create from JSON
  factory PowerCommandDto.fromJson(Map<String, dynamic> json) {
    return PowerCommandDto(
      deviceId: json['deviceId'] as String,
      powerOn: json['powerOn'] as bool,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'deviceId': deviceId, 'powerOn': powerOn};
  }
}
