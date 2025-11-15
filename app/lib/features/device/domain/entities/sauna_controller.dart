/// Sauna controller domain entity
library;

import 'package:equatable/equatable.dart';

/// Power state of the sauna
enum PowerState {
  off,
  on,
  unknown;

  bool get isOn => this == PowerState.on;
  bool get isOff => this == PowerState.off;
}

/// Heating status of the sauna
enum HeatingStatus {
  idle,
  heating,
  cooling,
  targetReached,
  unknown;

  bool get isHeating => this == HeatingStatus.heating;
  bool get isIdle => this == HeatingStatus.idle;
}

/// Connection status of the device
enum ConnectionStatus {
  online,
  offline,
  connecting,
  unknown;

  bool get isOnline => this == ConnectionStatus.online;
  bool get isOffline => this == ConnectionStatus.offline;
}

/// Sauna controller entity
///
/// Represents a sauna controller device with its current state
class SaunaController extends Equatable {
  final String deviceId;
  final String name;
  final String modelNumber;
  final String serialNumber;
  final PowerState powerState;
  final HeatingStatus heatingStatus;
  final ConnectionStatus connectionStatus;
  final double? currentTemperature;
  final double? targetTemperature;
  final double? minTemperature;
  final double? maxTemperature;
  final double? currentHumidity;
  final double? targetHumidity;
  final DateTime? lastUpdated;
  final List<String> linkedSensorIds;

  const SaunaController({
    required this.deviceId,
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
    this.linkedSensorIds = const [],
  });

  @override
  List<Object?> get props => [
    deviceId,
    name,
    modelNumber,
    serialNumber,
    powerState,
    heatingStatus,
    connectionStatus,
    currentTemperature,
    targetTemperature,
    minTemperature,
    maxTemperature,
    currentHumidity,
    targetHumidity,
    lastUpdated,
    linkedSensorIds,
  ];

  /// Check if controller is operational
  bool get isOperational =>
      connectionStatus.isOnline && powerState != PowerState.unknown;

  /// Check if controller has temperature data
  bool get hasTemperature => currentTemperature != null;

  /// Check if controller has target temperature set
  bool get hasTarget => targetTemperature != null;

  /// Check if controller has humidity data
  bool get hasHumidity => currentHumidity != null;

  /// Check if controller has target humidity set
  bool get hasTargetHumidity => targetHumidity != null;

  /// Check if temperature is at target
  bool get isAtTarget {
    if (currentTemperature == null || targetTemperature == null) return false;
    return (currentTemperature! - targetTemperature!).abs() <= 2.0;
  }

  /// Check if controller has linked sensors
  bool get hasSensors => linkedSensorIds.isNotEmpty;

  /// Calculate temperature progress (0.0 to 1.0)
  double? get temperatureProgress {
    if (currentTemperature == null ||
        targetTemperature == null ||
        minTemperature == null) {
      return null;
    }

    final range = targetTemperature! - minTemperature!;
    if (range <= 0) return null;

    final current = currentTemperature! - minTemperature!;
    return (current / range).clamp(0.0, 1.0);
  }

  /// Copy with updated fields
  SaunaController copyWith({
    String? deviceId,
    String? name,
    String? modelNumber,
    String? serialNumber,
    PowerState? powerState,
    HeatingStatus? heatingStatus,
    ConnectionStatus? connectionStatus,
    double? currentTemperature,
    double? targetTemperature,
    double? minTemperature,
    double? maxTemperature,
    double? currentHumidity,
    double? targetHumidity,
    DateTime? lastUpdated,
    List<String>? linkedSensorIds,
  }) {
    return SaunaController(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      powerState: powerState ?? this.powerState,
      heatingStatus: heatingStatus ?? this.heatingStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      currentHumidity: currentHumidity ?? this.currentHumidity,
      targetHumidity: targetHumidity ?? this.targetHumidity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      linkedSensorIds: linkedSensorIds ?? this.linkedSensorIds,
    );
  }

  /// Create empty controller
  factory SaunaController.empty() {
    return const SaunaController(
      deviceId: '',
      name: '',
      modelNumber: '',
      serialNumber: '',
      powerState: PowerState.unknown,
      heatingStatus: HeatingStatus.unknown,
      connectionStatus: ConnectionStatus.unknown,
    );
  }
}
