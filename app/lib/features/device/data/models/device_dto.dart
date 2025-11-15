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
  final double? currentHumidity;
  final double? targetHumidity;
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
    this.currentHumidity,
    this.targetHumidity,
    this.lastUpdated,
    this.linkedSensorIds,
  });

  /// From GraphQL JSON
  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    // Parse attr array into a map for easier access
    final attrs = <String, String>{};
    final attrList = json['attr'] as List<dynamic>?;
    if (attrList != null) {
      for (final attr in attrList) {
        final key = attr['key'] as String?;
        final value = attr['value'] as String?;
        if (key != null && value != null) {
          attrs[key] = value;
        }
      }
    }

    // Extract device type from JSON (name field in API response is actually the device ID)
    final deviceType = json['type'] as String?;

    return DeviceDto(
      id: json['name'] as String? ?? json['id'] as String,
      name: attrs['name'] ?? attrs['serialNumber'] ?? '',
      modelNumber: deviceType ?? attrs['modelNumber'] ?? attrs['model'] ?? '',
      serialNumber: attrs['serialNumber'] ?? attrs['serial'] ?? '',
      powerState: attrs['powerState'] ?? 'unknown',
      heatingStatus: attrs['heatingStatus'] ?? 'unknown',
      connectionStatus:
          attrs['connectionStatus'] ?? attrs['connected'] ?? 'unknown',
      currentTemperature: double.tryParse(attrs['currentTemperature'] ?? ''),
      targetTemperature: double.tryParse(attrs['targetTemperature'] ?? ''),
      minTemperature: double.tryParse(attrs['minTemperature'] ?? ''),
      maxTemperature: double.tryParse(attrs['maxTemperature'] ?? ''),
      currentHumidity: double.tryParse(attrs['currentHumidity'] ?? ''),
      targetHumidity: double.tryParse(attrs['targetHumidity'] ?? ''),
      lastUpdated: attrs['lastUpdated'],
      linkedSensorIds: attrs['linkedSensorIds']?.split(','),
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
      if (currentHumidity != null) 'currentHumidity': currentHumidity,
      if (targetHumidity != null) 'targetHumidity': targetHumidity,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
      if (linkedSensorIds != null) 'linkedSensorIds': linkedSensorIds,
    };
  }

  /// Convert to domain entity
  SaunaController toDomain() {
    return SaunaController(
      deviceId: id,
      name: name,
      deviceType: _parseDeviceType(modelNumber),
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      powerState: _parsePowerState(powerState),
      heatingStatus: _parseHeatingStatus(heatingStatus),
      connectionStatus: _parseConnectionStatus(connectionStatus),
      currentTemperature: currentTemperature,
      targetTemperature: targetTemperature,
      minTemperature: minTemperature,
      maxTemperature: maxTemperature,
      currentHumidity: currentHumidity,
      targetHumidity: targetHumidity,
      lastUpdated: lastUpdated != null ? DateTime.parse(lastUpdated!) : null,
      linkedSensorIds: linkedSensorIds ?? [],
    );
  }

  /// Parse device type from string
  static DeviceType _parseDeviceType(String value) {
    switch (value.toUpperCase()) {
      case 'FENIX':
        return DeviceType.fenix;
      case 'SAUNASENSOR':
        return DeviceType.saunaSensor;
      default:
        return DeviceType.unknown;
    }
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
