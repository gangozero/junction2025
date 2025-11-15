/// Sensor data transfer objects
library;

import '../../domain/entities/sensor_device.dart';

/// Sensor DTO from GraphQL API
///
/// Maps GraphQL sensor response to domain entity
class SensorDto {
  final String id;
  final String name;
  final String type;
  final String? linkedControllerId;
  final double? temperature;
  final double? humidity;
  final int? batteryLevel;
  final String? lastUpdated;
  final bool isOnline;

  const SensorDto({
    required this.id,
    required this.name,
    required this.type,
    this.linkedControllerId,
    this.temperature,
    this.humidity,
    this.batteryLevel,
    this.lastUpdated,
    this.isOnline = false,
  });

  /// From GraphQL JSON
  factory SensorDto.fromJson(Map<String, dynamic> json) {
    return SensorDto(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      linkedControllerId: json['linkedControllerId'] as String?,
      temperature: json['temperature'] as double?,
      humidity: json['humidity'] as double?,
      batteryLevel: json['batteryLevel'] as int?,
      lastUpdated: json['lastUpdated'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  /// To GraphQL JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (linkedControllerId != null) 'linkedControllerId': linkedControllerId,
      if (temperature != null) 'temperature': temperature,
      if (humidity != null) 'humidity': humidity,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
      'isOnline': isOnline,
    };
  }

  /// Convert to domain entity
  SensorDevice toDomain() {
    return SensorDevice(
      deviceId: id,
      name: name,
      type: _parseSensorType(type),
      linkedControllerId: linkedControllerId,
      temperature: temperature,
      humidity: humidity,
      batteryLevel: batteryLevel,
      lastUpdated: lastUpdated != null ? DateTime.parse(lastUpdated!) : null,
      isOnline: isOnline,
    );
  }

  /// Parse sensor type from string
  static SensorType _parseSensorType(String value) {
    switch (value.toUpperCase()) {
      case 'TEMPERATURE':
        return SensorType.temperature;
      case 'HUMIDITY':
        return SensorType.humidity;
      case 'TEMPERATURE_HUMIDITY':
      case 'TEMP_HUMIDITY':
        return SensorType.temperatureHumidity;
      default:
        return SensorType.unknown;
    }
  }
}
