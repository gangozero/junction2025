/// Command validation use case
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../device/domain/entities/sauna_controller.dart';
import '../entities/command_request.dart';
import '../repositories/control_repository.dart';

/// Command validation use case
///
/// Prevents conflicting or invalid commands from being sent
class ValidateCommandUseCase {
  final ControlRepository repository;

  const ValidateCommandUseCase({required this.repository});

  /// Validate power command
  ///
  /// Returns Either<Failure, void> - Left if validation fails, Right if valid
  Future<Either<Failure, void>> validatePowerCommand({
    required SaunaController device,
    required bool powerOn,
  }) async {
    // Check if device is offline
    if (device.connectionStatus == ConnectionStatus.offline) {
      return const Left(
        ValidationFailure('Cannot send commands to offline device'),
      );
    }

    // Check if device is already in target state
    if (powerOn && device.powerState == PowerState.on) {
      return const Left(ValidationFailure('Device is already powered on'));
    }

    if (!powerOn && device.powerState == PowerState.off) {
      return const Left(ValidationFailure('Device is already powered off'));
    }

    // Check for pending commands
    final pendingResult = await repository.getPendingCommands(
      deviceId: device.deviceId,
    );

    return pendingResult.fold((failure) => Left(failure), (pendingCommands) {
      // Check for in-flight power commands
      final hasPendingPowerCommand = pendingCommands.any(
        (cmd) =>
            cmd.type.isPowerCommand &&
            (cmd.status == CommandStatus.pending ||
                cmd.status == CommandStatus.inProgress),
      );

      if (hasPendingPowerCommand) {
        return const Left(
          ValidationFailure(
            'Another power command is already in progress. Please wait.',
          ),
        );
      }

      return const Right(null);
    });
  }

  /// Validate temperature command
  ///
  /// Returns Either<Failure, void> - Left if validation fails, Right if valid
  Future<Either<Failure, void>> validateTemperatureCommand({
    required SaunaController device,
    required double targetTemperature,
  }) async {
    // Check if device is offline
    if (device.connectionStatus == ConnectionStatus.offline) {
      return const Left(
        ValidationFailure('Cannot send commands to offline device'),
      );
    }

    // Check if device is powered off
    if (device.powerState == PowerState.off) {
      return const Left(
        ValidationFailure(
          'Cannot adjust temperature while device is powered off',
        ),
      );
    }

    // Validate temperature range (Harvia saunas typically 40-110°C)
    const minTemp = 40.0;
    const maxTemp = 110.0;

    if (targetTemperature < minTemp || targetTemperature > maxTemp) {
      return Left(
        ValidationFailure(
          'Temperature must be between ${minTemp.toInt()}°C and ${maxTemp.toInt()}°C',
        ),
      );
    }

    // Check if temperature is same as current target
    if (device.targetTemperature != null &&
        (device.targetTemperature! - targetTemperature).abs() < 0.5) {
      return const Left(
        ValidationFailure('Target temperature is already set to this value'),
      );
    }

    // Check for pending commands
    final pendingResult = await repository.getPendingCommands(
      deviceId: device.deviceId,
    );

    return pendingResult.fold((failure) => Left(failure), (pendingCommands) {
      // Check for in-flight temperature commands
      final hasPendingTempCommand = pendingCommands.any(
        (cmd) =>
            cmd.type == CommandType.setTemperature &&
            (cmd.status == CommandStatus.pending ||
                cmd.status == CommandStatus.inProgress),
      );

      if (hasPendingTempCommand) {
        return const Left(
          ValidationFailure(
            'Another temperature command is already in progress. Please wait.',
          ),
        );
      }

      return const Right(null);
    });
  }

  /// Check if any command is in progress for a device
  Future<bool> hasCommandInProgress(String deviceId) async {
    final pendingResult = await repository.getPendingCommands(
      deviceId: deviceId,
    );

    return pendingResult.fold(
      (failure) => false,
      (pendingCommands) => pendingCommands.any(
        (cmd) =>
            cmd.status == CommandStatus.pending ||
            cmd.status == CommandStatus.inProgress,
      ),
    );
  }
}
