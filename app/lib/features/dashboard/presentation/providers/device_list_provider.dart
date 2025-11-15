/// Device list state provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../device/data/datasources/device_local_datasource.dart';
import '../../../device/data/datasources/device_remote_datasource.dart';
import '../../../device/data/repositories/device_repository_impl.dart';
import '../../../device/domain/entities/sauna_controller.dart';
import '../../../device/domain/repositories/device_repository.dart';

/// Device repository provider
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    remoteDataSource: DeviceRemoteDataSource.create(),
    localDataSource: DeviceLocalDataSource(),
  );
});

/// Device list provider
///
/// Provides list of all devices for the current user
final deviceListProvider = FutureProvider<List<SaunaController>>((ref) async {
  final repository = ref.read(deviceRepositoryProvider);
  final result = await repository.getDevices();
  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (devices) => devices,
  );
});

/// Provides the state of a single device, including temperature.
final deviceStateProvider = FutureProvider.family<SaunaController, String>((
  ref,
  deviceId,
) async {
  final repository = ref.read(deviceRepositoryProvider);

  // First, get all devices and find the one we are interested in.
  // This avoids fetching the device state again if we already have it.
  final devices = await ref.watch(deviceListProvider.future);
  final device = devices.firstWhere(
    (d) => d.deviceId == deviceId,
    orElse: () => throw Exception('Device with ID $deviceId not found'),
  );

  // Now, fetch the latest measurements for this device.
  final measurementsResult = await repository.getLatestMeasurements(deviceId);

  return measurementsResult.fold(
    (failure) {
      // If measurements fail, return the original device state
      return device;
    },
    (measurements) {
      // The measurements are now parsed JSON data objects
      // Look for temperature data in any of the measurement items
      double? temperature;

      for (final measurement in measurements) {
        // Try different possible field names for temperature
        final temp =
            measurement['temp'] ??
            measurement['temperature'] ??
            measurement['SAUNA_TEMP_C'];

        if (temp != null) {
          temperature = double.tryParse(temp.toString());
          if (temperature != null) {
            break; // Found a valid temperature, stop looking
          }
        }
      }

      if (temperature != null) {
        // Return a new SaunaController with the updated temperature.
        return device.copyWith(currentTemperature: temperature);
      }

      // If no temperature data, return the original device state.
      return device;
    },
  );
});

/// Specific device provider
///
/// Provides details for a single device by ID
final deviceProvider = FutureProvider.family<SaunaController, String>((
  ref,
  deviceId,
) async {
  final repository = ref.read(deviceRepositoryProvider);

  final result = await repository.getDeviceState(deviceId);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (device) => device,
  );
});

/// Cached devices provider (offline-first)
///
/// Returns immediately from cache without network call
final cachedDevicesProvider = FutureProvider<List<SaunaController>>((
  ref,
) async {
  final repository = ref.read(deviceRepositoryProvider);

  final result = await repository.getCachedDevices();

  return result.fold((failure) => [], (devices) => devices);
});
