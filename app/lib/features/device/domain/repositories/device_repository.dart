/// Device repository interface
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/sauna_controller.dart';
import '../entities/sensor_device.dart';

/// Device repository
///
/// Handles device and sensor data retrieval with offline-first caching
abstract class DeviceRepository {
  /// Get list of all devices for the current user
  ///
  /// Returns cached data if available, then fetches from API.
  /// Updates cache with fresh data.
  ///
  /// Returns [NetworkFailure] if offline and no cache available.
  /// Returns [ApiFailure] on API errors.
  Future<Either<Failure, List<SaunaController>>> getDevices();

  /// Get detailed state of a specific device
  ///
  /// [deviceId] - ID of the device to fetch
  ///
  /// Returns cached data if available, then fetches from API.
  ///
  /// Returns [ApiFailure] if device not found or API error.
  Future<Either<Failure, SaunaController>> getDeviceState(String deviceId);

  /// Get latest measurements for a device
  ///
  /// [deviceId] - ID of the device to fetch measurements for
  ///
  /// Returns a list of measurements.
  Future<Either<Failure, List<Map<String, dynamic>>>> getLatestMeasurements(
    String deviceId,
  );

  /// Subscribe to device state changes via WebSocket
  ///
  /// [deviceId] - ID of the device to subscribe to
  ///
  /// Returns a stream of device state updates.
  /// Stream automatically reconnects on connection loss.
  ///
  /// Emits [NetworkFailure] on connection errors.
  Stream<Either<Failure, SaunaController>> subscribeToDeviceState(
    String deviceId,
  );

  /// Get list of sensors for a specific controller
  ///
  /// [controllerId] - ID of the controller
  ///
  /// Returns all sensors linked to this controller plus unlinked sensors.
  ///
  /// Returns [ApiFailure] on API errors.
  Future<Either<Failure, List<SensorDevice>>> getSensors(String controllerId);

  /// Get latest sensor data
  ///
  /// [sensorId] - ID of the sensor
  ///
  /// Returns current sensor readings (temperature, humidity, battery).
  ///
  /// Returns [ApiFailure] if sensor not found.
  Future<Either<Failure, SensorDevice>> getSensorData(String sensorId);

  /// Subscribe to sensor data updates via WebSocket
  ///
  /// [sensorId] - ID of the sensor to subscribe to
  ///
  /// Returns a stream of sensor data updates.
  ///
  /// Emits [NetworkFailure] on connection errors.
  Stream<Either<Failure, SensorDevice>> subscribeToSensorData(String sensorId);

  /// Link a sensor to a controller
  ///
  /// [sensorId] - ID of the sensor
  /// [controllerId] - ID of the controller
  ///
  /// Updates both local cache and remote API.
  ///
  /// Returns [ApiFailure] on validation or API errors.
  Future<Either<Failure, void>> linkSensor({
    required String sensorId,
    required String controllerId,
  });

  /// Unlink a sensor from a controller
  ///
  /// [sensorId] - ID of the sensor to unlink
  ///
  /// Removes association in cache and remote API.
  ///
  /// Returns [ApiFailure] on API errors.
  Future<Either<Failure, void>> unlinkSensor(String sensorId);

  /// Save device to local cache
  ///
  /// [device] - Device to cache
  ///
  /// Returns [CacheFailure] if storage operation fails.
  Future<Either<Failure, void>> cacheDevice(SaunaController device);

  /// Save sensor to local cache
  ///
  /// [sensor] - Sensor to cache
  ///
  /// Returns [CacheFailure] if storage operation fails.
  Future<Either<Failure, void>> cacheSensor(SensorDevice sensor);

  /// Get devices from local cache only
  ///
  /// Returns empty list if cache is empty.
  /// Returns [CacheFailure] if storage read fails.
  Future<Either<Failure, List<SaunaController>>> getCachedDevices();

  /// Get specific device from local cache
  ///
  /// [deviceId] - ID of device to retrieve
  ///
  /// Returns [CacheFailure] if not found or storage read fails.
  Future<Either<Failure, SaunaController>> getCachedDevice(String deviceId);

  /// Clear all cached device data
  ///
  /// Returns [CacheFailure] if storage operation fails.
  Future<Either<Failure, void>> clearCache();
}
