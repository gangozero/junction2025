/// Control repository interface
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/command_request.dart';

/// Control repository interface
///
/// Defines contract for sending control commands to sauna controllers
abstract class ControlRepository {
  /// Send power command to device
  ///
  /// Returns Either<Failure, CommandRequest> with updated command status
  Future<Either<Failure, CommandRequest>> sendPowerCommand({
    required String deviceId,
    required bool powerOn,
  });

  /// Send temperature command to device
  ///
  /// Returns Either<Failure, CommandRequest> with updated command status
  Future<Either<Failure, CommandRequest>> sendTemperatureCommand({
    required String deviceId,
    required double targetTemperature,
  });

  /// Get pending commands for a device (from local queue)
  Future<Either<Failure, List<CommandRequest>>> getPendingCommands({
    required String deviceId,
  });

  /// Retry a failed command
  Future<Either<Failure, CommandRequest>> retryCommand({
    required CommandRequest command,
  });

  /// Cancel a pending command
  Future<Either<Failure, void>> cancelCommand({required String commandId});

  /// Clear completed commands older than specified duration
  Future<Either<Failure, void>> clearOldCommands({
    Duration age = const Duration(hours: 24),
  });
}
