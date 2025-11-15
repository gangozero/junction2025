/// Sensor device domain entity
library;

import 'package:equatable/equatable.dart';

/// Type of sensor
enum SensorType {
  temperature,
  humidity,
  temperatureHumidity,
  unknown;

  bool get hasTemperature =>
      this == SensorType.temperature || this == SensorType.temperatureHumidity;

  bool get hasHumidity =>
      this == SensorType.humidity || this == SensorType.temperatureHumidity;
}

/// Sensor device entity
///
/// Represents a sensor device that can measure temperature and/or humidity
class SensorDevice extends Equatable {
  final String deviceId;
  final String name;
  final SensorType type;
  final String? linkedControllerId;
  final double? temperature;
  final double? humidity;
  final int? batteryLevel;
  final DateTime? lastUpdated;
  final bool isOnline;

  const SensorDevice({
    required this.deviceId,
    required this.name,
    required this.type,
    this.linkedControllerId,
    this.temperature,
    this.humidity,
    this.batteryLevel,
    this.lastUpdated,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [
    deviceId,
    name,
    type,
    linkedControllerId,
    temperature,
    humidity,
    batteryLevel,
    lastUpdated,
    isOnline,
  ];

  /// Check if sensor is linked to a controller
  bool get isLinked => linkedControllerId != null;

  /// Check if sensor has temperature data
  bool get hasTemperature => temperature != null && type.hasTemperature;

  /// Check if sensor has humidity data
  bool get hasHumidity => humidity != null && type.hasHumidity;

  /// Check if battery is low (below 20%)
  bool get isBatteryLow => batteryLevel != null && batteryLevel! < 20;

  /// Check if sensor data is stale (older than 5 minutes)
  bool get isDataStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

  /// Check if sensor is operational
  bool get isOperational => isOnline && !isDataStale;

  /// Copy with updated fields
  SensorDevice copyWith({
    String? deviceId,
    String? name,
    SensorType? type,
    String? linkedControllerId,
    double? temperature,
    double? humidity,
    int? batteryLevel,
    DateTime? lastUpdated,
    bool? isOnline,
    bool clearLinkedController = false,
  }) {
    return SensorDevice(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      linkedControllerId: clearLinkedController
          ? null
          : (linkedControllerId ?? this.linkedControllerId),
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  /// Create empty sensor
  factory SensorDevice.empty() {
    return const SensorDevice(deviceId: '', name: '', type: SensorType.unknown);
  }
}
