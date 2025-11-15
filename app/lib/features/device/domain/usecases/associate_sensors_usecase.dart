/// Associate sensors to controller use case
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/sensor_device.dart';
import '../../domain/repositories/device_repository.dart';

/// Associate sensors use case
///
/// Implements automatic sensor-controller association logic based on proximity
/// and manual linking functionality
class AssociateSensorsUseCase {
  final DeviceRepository _repository;

  AssociateSensorsUseCase({required DeviceRepository repository})
    : _repository = repository;

  /// Automatically associate sensors to a controller
  ///
  /// Logic:
  /// 1. Get all sensors for the controller
  /// 2. Find unlinked sensors that are online
  /// 3. Suggest sensors based on proximity/signal strength (if available)
  ///
  /// Returns list of suggested sensors that could be linked
  Future<Either<Failure, List<SensorDevice>>> getSuggestedSensors(
    String controllerId,
  ) async {
    try {
      final result = await _repository.getSensors(controllerId);

      return result.fold((failure) => Left(failure), (sensors) {
        // Filter for unlinked sensors that are online
        final unlinkedSensors = sensors
            .where((sensor) => !sensor.isLinked && sensor.isOnline)
            .toList();

        AppLogger.device(
          controllerId,
          'Found ${unlinkedSensors.length} unlinked sensors',
        );

        // Sort by operational status (online, good battery, recent data)
        unlinkedSensors.sort((a, b) {
          // Prioritize operational sensors
          if (a.isOperational && !b.isOperational) return -1;
          if (!a.isOperational && b.isOperational) return 1;

          // Then by battery level
          final aBattery = a.batteryLevel ?? 0;
          final bBattery = b.batteryLevel ?? 0;
          if (aBattery != bBattery) return bBattery.compareTo(aBattery);

          // Then by last update time
          if (a.lastUpdated != null && b.lastUpdated != null) {
            return b.lastUpdated!.compareTo(a.lastUpdated!);
          }

          return 0;
        });

        return Right(unlinkedSensors);
      });
    } catch (e) {
      AppLogger.e('Failed to get suggested sensors', error: e);
      return Left(UnknownFailure('Failed to get suggested sensors', e));
    }
  }

  /// Link a sensor to a controller
  ///
  /// Validates that sensor exists and is not already linked
  Future<Either<Failure, void>> linkSensor({
    required String sensorId,
    required String controllerId,
  }) async {
    try {
      // Get sensor to validate it exists
      final sensorResult = await _repository.getSensorData(sensorId);

      return await sensorResult.fold((failure) => Left(failure), (
        sensor,
      ) async {
        // Check if already linked
        if (sensor.isLinked && sensor.linkedControllerId != controllerId) {
          AppLogger.w(
            'Sensor $sensorId already linked to ${sensor.linkedControllerId}',
          );
          return const Left(
            ApiFailure('Sensor is already linked to another controller'),
          );
        }

        // Link the sensor
        final linkResult = await _repository.linkSensor(
          sensorId: sensorId,
          controllerId: controllerId,
        );

        return linkResult.fold((failure) => Left(failure), (_) {
          AppLogger.device(
            controllerId,
            'Successfully linked sensor $sensorId',
          );
          return const Right(null);
        });
      });
    } catch (e) {
      AppLogger.e('Failed to link sensor', error: e);
      return Left(UnknownFailure('Failed to link sensor', e));
    }
  }

  /// Unlink a sensor from its controller
  Future<Either<Failure, void>> unlinkSensor(String sensorId) async {
    try {
      final result = await _repository.unlinkSensor(sensorId);

      return result.fold((failure) => Left(failure), (_) {
        AppLogger.d('Successfully unlinked sensor $sensorId');
        return const Right(null);
      });
    } catch (e) {
      AppLogger.e('Failed to unlink sensor', error: e);
      return Left(UnknownFailure('Failed to unlink sensor', e));
    }
  }

  /// Get all sensors linked to a controller
  Future<Either<Failure, List<SensorDevice>>> getLinkedSensors(
    String controllerId,
  ) async {
    try {
      final result = await _repository.getSensors(controllerId);

      return result.fold((failure) => Left(failure), (sensors) {
        final linkedSensors = sensors
            .where(
              (sensor) =>
                  sensor.isLinked && sensor.linkedControllerId == controllerId,
            )
            .toList();

        AppLogger.device(
          controllerId,
          'Found ${linkedSensors.length} linked sensors',
        );

        return Right(linkedSensors);
      });
    } catch (e) {
      AppLogger.e('Failed to get linked sensors', error: e);
      return Left(UnknownFailure('Failed to get linked sensors', e));
    }
  }
}
