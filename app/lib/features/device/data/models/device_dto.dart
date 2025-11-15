/// Device data transfer objects
library;

import '../../domain/entities/sauna_controller.dart';

/// Device DTO from GraphQL API
///
/// Maps GraphQL device response to domain entity
class DeviceDto {
  final String id;
  final String name;
  final String modelNumber;
  final String serialNumber;
  final String powerState;
  final String heatingStatus;
  final String connectionStatus;
  final double? currentTemperature;
  final double? targetTemperature;
  final double? minTemperature;
  final double? maxTemperature;
  final String? lastUpdated;
  final List<String>? linkedSensorIds;

  const DeviceDto({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.serialNumber,
    required this.powerState,
    required this.heatingStatus,
    required this.connectionStatus,
    this.currentTemperature,
    this.targetTemperature,
    this.minTemperature,
    this.maxTemperature,
    this.lastUpdated,
    this.linkedSensorIds,
  });

  /// From GraphQL JSON
  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    return DeviceDto(
      id: json['id'] as String,
      name: json['name'] as String,
      modelNumber: json['modelNumber'] as String,
      serialNumber: json['serialNumber'] as String,
      powerState: json['powerState'] as String,
      heatingStatus: json['heatingStatus'] as String,
      connectionStatus: json['connectionStatus'] as String,
      currentTemperature: json['currentTemperature'] as double?,
      targetTemperature: json['targetTemperature'] as double?,
      minTemperature: json['minTemperature'] as double?,
      maxTemperature: json['maxTemperature'] as double?,
      lastUpdated: json['lastUpdated'] as String?,
      linkedSensorIds: (json['linkedSensorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  /// To GraphQL JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modelNumber': modelNumber,
      'serialNumber': serialNumber,
      'powerState': powerState,
      'heatingStatus': heatingStatus,
      'connectionStatus': connectionStatus,
      if (currentTemperature != null) 'currentTemperature': currentTemperature,
      if (targetTemperature != null) 'targetTemperature': targetTemperature,
      if (minTemperature != null) 'minTemperature': minTemperature,
      if (maxTemperature != null) 'maxTemperature': maxTemperature,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
      if (linkedSensorIds != null) 'linkedSensorIds': linkedSensorIds,
    };
  }

  /// Convert to domain entity
  SaunaController toDomain() {
    return SaunaController(
      deviceId: id,
      name: name,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      powerState: _parsePowerState(powerState),
      heatingStatus: _parseHeatingStatus(heatingStatus),
      connectionStatus: _parseConnectionStatus(connectionStatus),
      currentTemperature: currentTemperature,
      targetTemperature: targetTemperature,
      minTemperature: minTemperature,
      maxTemperature: maxTemperature,
      lastUpdated: lastUpdated != null ? DateTime.parse(lastUpdated!) : null,
      linkedSensorIds: linkedSensorIds ?? [],
    );
  }

  /// Parse power state from string
  static PowerState _parsePowerState(String value) {
    switch (value.toUpperCase()) {
      case 'ON':
        return PowerState.on;
      case 'OFF':
        return PowerState.off;
      default:
        return PowerState.unknown;
    }
  }

  /// Parse heating status from string
  static HeatingStatus _parseHeatingStatus(String value) {
    switch (value.toUpperCase()) {
      case 'IDLE':
        return HeatingStatus.idle;
      case 'HEATING':
        return HeatingStatus.heating;
      case 'COOLING':
        return HeatingStatus.cooling;
      case 'TARGET_REACHED':
        return HeatingStatus.targetReached;
      default:
        return HeatingStatus.unknown;
    }
  }

  /// Parse connection status from string
  static ConnectionStatus _parseConnectionStatus(String value) {
    switch (value.toUpperCase()) {
      case 'ONLINE':
        return ConnectionStatus.online;
      case 'OFFLINE':
        return ConnectionStatus.offline;
      case 'CONNECTING':
        return ConnectionStatus.connecting;
      default:
        return ConnectionStatus.unknown;
    }
  }
}
