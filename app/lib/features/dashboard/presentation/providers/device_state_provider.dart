/// Device state stream provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../device/domain/entities/sauna_controller.dart';
import '../../../device/domain/entities/sensor_device.dart';
import 'device_list_provider.dart';

/// Device state stream provider
///
/// Provides real-time device state updates via WebSocket subscription
final deviceStateStreamProvider =
    StreamProvider.family<SaunaController, String>((ref, deviceId) {
      final repository = ref.read(deviceRepositoryProvider);

      return repository.subscribeToDeviceState(deviceId).asyncMap((result) {
        return result.fold(
          (failure) => throw Exception(failure.userMessage),
          (device) => device,
        );
      });
    });

/// Sensor data stream provider
///
/// Provides real-time sensor data updates via WebSocket subscription
final sensorDataStreamProvider = StreamProvider.family<SensorDevice, String>((
  ref,
  sensorId,
) {
  final repository = ref.read(deviceRepositoryProvider);

  return repository.subscribeToSensorData(sensorId).asyncMap((result) {
    return result.fold(
      (failure) => throw Exception(failure.userMessage),
      (sensor) => sensor,
    );
  });
});

/// Sensors for controller provider
///
/// Provides list of sensors linked to a specific controller
final sensorsForControllerProvider =
    FutureProvider.family<List<SensorDevice>, String>((
      ref,
      controllerId,
    ) async {
      final repository = ref.read(deviceRepositoryProvider);

      final result = await repository.getSensors(controllerId);

      return result.fold(
        (failure) => throw Exception(failure.userMessage),
        (sensors) => sensors,
      );
    });
