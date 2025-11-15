/// Device repository implementation
library;

import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/sauna_controller.dart';
import '../../domain/entities/sensor_device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device_local_datasource.dart';
import '../datasources/device_remote_datasource.dart';

/// Device repository implementation
///
/// Implements offline-first strategy:
/// 1. Return cached data immediately if available
/// 2. Fetch from API in background
/// 3. Update cache with fresh data
class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _remoteDataSource;
  final DeviceLocalDataSource _localDataSource;

  DeviceRepositoryImpl({
    required DeviceRemoteDataSource remoteDataSource,
    required DeviceLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<SaunaController>>> getDevices() async {
    try {
      // Try to get from cache first
      final cachedDevices = await _localDataSource.getDevices();

      // Fetch from API
      try {
        final deviceDtos = await _remoteDataSource.listDevices();
        final devices = deviceDtos.map((dto) => dto.toDomain()).toList();

        // Update cache
        for (final device in devices) {
          await _localDataSource.saveDevice(device);
        }

        AppLogger.device('all', 'Fetched ${devices.length} devices from API');
        return Right(devices);
      } on OperationException catch (e) {
        // Network error - return cached data if available
        if (cachedDevices.isNotEmpty) {
          AppLogger.w('API failed, returning cached devices', error: e);
          return Right(cachedDevices);
        }

        return Left(_handleGraphQLException(e));
      }
    } catch (e) {
      AppLogger.e('Failed to get devices', error: e);
      return Left(UnknownFailure('Failed to get devices', e));
    }
  }

  @override
  Future<Either<Failure, SaunaController>> getDeviceState(
    String deviceId,
  ) async {
    try {
      // Try to get from cache first
      final cachedDevice = await _localDataSource.getDevice(deviceId);

      // Fetch from API
      try {
        final deviceDto = await _remoteDataSource.getDeviceState(deviceId);
        final device = deviceDto.toDomain();

        // Update cache
        await _localDataSource.saveDevice(device);

        AppLogger.device(deviceId, 'Fetched device state from API');
        return Right(device);
      } on OperationException catch (e) {
        // Network error - return cached data if available
        if (cachedDevice != null) {
          AppLogger.w('API failed, returning cached device', error: e);
          return Right(cachedDevice);
        }

        return Left(_handleGraphQLException(e));
      }
    } catch (e) {
      AppLogger.e('Failed to get device state', error: e);
      return Left(UnknownFailure('Failed to get device state', e));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getLatestMeasurements(
    String deviceId,
  ) async {
    try {
      final measurements = await _remoteDataSource.getLatestMeasurements(
        deviceId,
      );
      return Right(measurements);
    } on OperationException catch (e) {
      return Left(_handleGraphQLException(e));
    } catch (e) {
      AppLogger.e('Failed to get latest measurements', error: e);
      return Left(UnknownFailure('Failed to get latest measurements', e));
    }
  }

  @override
  Stream<Either<Failure, SaunaController>> subscribeToDeviceState(
    String deviceId,
  ) async* {
    try {
      AppLogger.device(deviceId, 'Subscribing to device state updates');

      final stream = _remoteDataSource.subscribeToDeviceState(deviceId);

      await for (final deviceDto in stream) {
        final device = deviceDto.toDomain();

        // Update cache with each update
        await _localDataSource.saveDevice(device);

        AppLogger.device(deviceId, 'Received state update');
        yield Right(device);
      }
    } on OperationException catch (e) {
      AppLogger.e('Device subscription failed', error: e);
      yield Left(_handleGraphQLException(e));
    } catch (e) {
      AppLogger.e('Device subscription error', error: e);
      yield Left(UnknownFailure('Subscription failed', e));
    }
  }

  @override
  Future<Either<Failure, List<SensorDevice>>> getSensors(
    String controllerId,
  ) async {
    try {
      // Try to get from cache first
      final cachedSensors = await _localDataSource.getSensorsForController(
        controllerId,
      );

      // Fetch from API
      try {
        final sensorDtos = await _remoteDataSource.listSensors(controllerId);
        final sensors = sensorDtos.map((dto) => dto.toDomain()).toList();

        // Update cache
        for (final sensor in sensors) {
          await _localDataSource.saveSensor(sensor);
        }

        AppLogger.device(
          controllerId,
          'Fetched ${sensors.length} sensors from API',
        );
        return Right(sensors);
      } on OperationException catch (e) {
        // Network error - return cached data if available
        if (cachedSensors.isNotEmpty) {
          AppLogger.w('API failed, returning cached sensors', error: e);
          return Right(cachedSensors);
        }

        return Left(_handleGraphQLException(e));
      }
    } catch (e) {
      AppLogger.e('Failed to get sensors', error: e);
      return Left(UnknownFailure('Failed to get sensors', e));
    }
  }

  @override
  Future<Either<Failure, SensorDevice>> getSensorData(String sensorId) async {
    try {
      // Try to get from cache first
      final cachedSensor = await _localDataSource.getSensor(sensorId);

      // Fetch from API
      try {
        final sensorDto = await _remoteDataSource.getLatestData(sensorId);
        final sensor = sensorDto.toDomain();

        // Update cache
        await _localDataSource.saveSensor(sensor);

        AppLogger.d('Fetched sensor data from API: $sensorId');
        return Right(sensor);
      } on OperationException catch (e) {
        // Network error - return cached data if available
        if (cachedSensor != null) {
          AppLogger.w('API failed, returning cached sensor', error: e);
          return Right(cachedSensor);
        }

        return Left(_handleGraphQLException(e));
      }
    } catch (e) {
      AppLogger.e('Failed to get sensor data', error: e);
      return Left(UnknownFailure('Failed to get sensor data', e));
    }
  }

  @override
  Stream<Either<Failure, SensorDevice>> subscribeToSensorData(
    String sensorId,
  ) async* {
    try {
      AppLogger.d('Subscribing to sensor data updates: $sensorId');

      final stream = _remoteDataSource.subscribeToSensorData(sensorId);

      await for (final sensorDto in stream) {
        final sensor = sensorDto.toDomain();

        // Update cache with each update
        await _localDataSource.saveSensor(sensor);

        AppLogger.d('Received sensor data update: $sensorId');
        yield Right(sensor);
      }
    } on OperationException catch (e) {
      AppLogger.e('Sensor subscription failed', error: e);
      yield Left(_handleGraphQLException(e));
    } catch (e) {
      AppLogger.e('Sensor subscription error', error: e);
      yield Left(UnknownFailure('Subscription failed', e));
    }
  }

  @override
  Future<Either<Failure, void>> linkSensor({
    required String sensorId,
    required String controllerId,
  }) async {
    try {
      // Note: This would require a mutation in the GraphQL API
      // For now, we'll update local cache only
      AppLogger.w('linkSensor not implemented - local cache only');

      final sensor = await _localDataSource.getSensor(sensorId);
      if (sensor == null) {
        return const Left(CacheFailure('Sensor not found in cache'));
      }

      final updatedSensor = sensor.copyWith(linkedControllerId: controllerId);
      await _localDataSource.saveSensor(updatedSensor);

      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to link sensor', error: e);
      return Left(UnknownFailure('Failed to link sensor', e));
    }
  }

  @override
  Future<Either<Failure, void>> unlinkSensor(String sensorId) async {
    try {
      // Note: This would require a mutation in the GraphQL API
      // For now, we'll update local cache only
      AppLogger.w('unlinkSensor not implemented - local cache only');

      final sensor = await _localDataSource.getSensor(sensorId);
      if (sensor == null) {
        return const Left(CacheFailure('Sensor not found in cache'));
      }

      final updatedSensor = sensor.copyWith(clearLinkedController: true);
      await _localDataSource.saveSensor(updatedSensor);

      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to unlink sensor', error: e);
      return Left(UnknownFailure('Failed to unlink sensor', e));
    }
  }

  @override
  Future<Either<Failure, void>> cacheDevice(SaunaController device) async {
    try {
      await _localDataSource.saveDevice(device);
      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to cache device', error: e);
      return Left(CacheFailure('Failed to cache device'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheSensor(SensorDevice sensor) async {
    try {
      await _localDataSource.saveSensor(sensor);
      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to cache sensor', error: e);
      return Left(CacheFailure('Failed to cache sensor'));
    }
  }

  @override
  Future<Either<Failure, List<SaunaController>>> getCachedDevices() async {
    try {
      final devices = await _localDataSource.getDevices();
      return Right(devices);
    } catch (e) {
      AppLogger.e('Failed to get cached devices', error: e);
      return Left(CacheFailure('Failed to get cached devices'));
    }
  }

  @override
  Future<Either<Failure, SaunaController>> getCachedDevice(
    String deviceId,
  ) async {
    try {
      final device = await _localDataSource.getDevice(deviceId);
      if (device == null) {
        return const Left(CacheFailure('Device not found in cache'));
      }
      return Right(device);
    } catch (e) {
      AppLogger.e('Failed to get cached device', error: e);
      return Left(CacheFailure('Failed to get cached device'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _localDataSource.clearAll();
      return const Right(null);
    } catch (e) {
      AppLogger.e('Failed to clear cache', error: e);
      return Left(CacheFailure('Failed to clear cache'));
    }
  }

  /// Handle GraphQL exceptions
  Failure _handleGraphQLException(OperationException exception) {
    AppLogger.e('GraphQL error', error: exception);

    // Check for network errors
    if (exception.linkException != null) {
      return const NetworkFailure('No internet connection');
    }

    // Check for GraphQL errors
    final graphqlErrors = exception.graphqlErrors;
    if (graphqlErrors.isNotEmpty) {
      final firstError = graphqlErrors.first;
      final message = firstError.message;

      // Check for authentication errors
      if (message.toLowerCase().contains('unauthorized') ||
          message.toLowerCase().contains('unauthenticated')) {
        return const AuthFailure(
          'Authentication required',
          AuthFailureReason.unauthorized,
        );
      }

      // Check for not found errors
      if (message.toLowerCase().contains('not found')) {
        return ApiFailure(message, 404);
      }

      return ApiFailure(message);
    }

    return const ApiFailure('GraphQL request failed');
  }
}
