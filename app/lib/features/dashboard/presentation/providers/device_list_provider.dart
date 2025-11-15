/// Device list state provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
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
      double? humidity;
      int? saunaStatus;
      HeatingStatus? heatingStatus;

      if (measurements.isEmpty) {
        // No measurements available for this device
        AppLogger.w('No measurements returned for device $deviceId');
        return device;
      }

      AppLogger.d(
        'Processing ${measurements.length} measurements for device $deviceId',
      );

      for (final measurement in measurements) {
        // Extract sauna status if available
        if (saunaStatus == null && measurement['saunaStatus'] != null) {
          saunaStatus = int.tryParse(measurement['saunaStatus'].toString());
        }

        // Try different possible field names for temperature
        // Common field names: temp, temperature, SAUNA_TEMP_C, saunaTemp
        final temp =
            measurement['temp'] ??
            measurement['temperature'] ??
            measurement['SAUNA_TEMP_C'] ??
            measurement['saunaTemp'] ??
            measurement['currentTemp'];

        if (temp != null && temperature == null) {
          temperature = double.tryParse(temp.toString());
        }

        // Try different possible field names for humidity
        // Common field names: hum, humidity, SAUNA_HUM
        final hum =
            measurement['hum'] ??
            measurement['humidity'] ??
            measurement['SAUNA_HUM'] ??
            measurement['currentHumidity'];

        if (hum != null && humidity == null) {
          humidity = double.tryParse(hum.toString());
        }

        // Break early if we found both
        if (temperature != null && humidity != null) {
          break;
        }
      }

      // Map saunaStatus to HeatingStatus enum
      // Based on API behavior:
      // 0 = off/standby
      // 1 = heating
      // 2 = cooling
      // 3 = idle/standby
      if (saunaStatus != null) {
        switch (saunaStatus) {
          case 0:
            heatingStatus = HeatingStatus.idle;
          case 1:
            heatingStatus = HeatingStatus.heating;
          case 2:
            heatingStatus = HeatingStatus.cooling;
          case 3:
            heatingStatus = HeatingStatus.idle;
          default:
            heatingStatus = HeatingStatus.unknown;
        }
      }

      // Build updated device state
      SaunaController updatedDevice = device;

      if (temperature != null) {
        AppLogger.i('✅ Found temperature $temperature°C for device $deviceId');
        updatedDevice = updatedDevice.copyWith(currentTemperature: temperature);
      }

      if (humidity != null) {
        AppLogger.i('✅ Found humidity $humidity% for device $deviceId');
        updatedDevice = updatedDevice.copyWith(currentHumidity: humidity);
      }

      if (heatingStatus != null) {
        final statusName = heatingStatus.name;
        AppLogger.d(
          'Device $deviceId heating status: $statusName (saunaStatus: $saunaStatus)',
        );
        updatedDevice = updatedDevice.copyWith(heatingStatus: heatingStatus);
      }

      // Log informational messages based on state
      if (temperature == null) {
        if (saunaStatus == 0) {
          AppLogger.d(
            'Device $deviceId is off/standby - no temperature data expected',
          );
        } else {
          AppLogger.w(
            '⚠️ No temperature field found in ${measurements.length} measurements for device $deviceId',
          );
          if (measurements.isNotEmpty) {
            final sampleKeys = measurements.first.keys.toList();
            AppLogger.d('Available fields in first measurement: $sampleKeys');
          }
        }
      }

      return updatedDevice;
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
