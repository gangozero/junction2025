/// Control repository implementation
library;

import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/command_request.dart';
import '../../domain/repositories/control_repository.dart';
import '../datasources/control_local_datasource.dart';
import '../datasources/control_remote_datasource.dart';

/// Control repository implementation
///
/// Coordinates between remote API and local command queue with retry logic
class ControlRepositoryImpl implements ControlRepository {
  final ControlRemoteDataSource remoteDataSource;
  final ControlLocalDataSource localDataSource;

  const ControlRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, CommandRequest>> sendPowerCommand({
    required String deviceId,
    required bool powerOn,
  }) async {
    try {
      // Create command request
      final command = powerOn
          ? CommandRequest.powerOn(deviceId: deviceId)
          : CommandRequest.powerOff(deviceId: deviceId);

      // Queue command locally first (offline-first)
      await localDataSource.queueCommand(command);

      // Update status to in-progress
      final inProgressCommand = command.copyWith(
        status: CommandStatus.inProgress,
        sentAt: DateTime.now(),
      );
      await localDataSource.updateCommand(inProgressCommand);

      // Attempt to send command
      return await _sendCommandWithRetry(inProgressCommand);
    } catch (e) {
      if (e is OperationException) {
        return Left(_handleGraphQLException(e));
      }
      return Left(CacheFailure('Failed to send power command: $e'));
    }
  }

  @override
  Future<Either<Failure, CommandRequest>> sendTemperatureCommand({
    required String deviceId,
    required double targetTemperature,
  }) async {
    try {
      // Create command request
      final command = CommandRequest.setTemperature(
        deviceId: deviceId,
        targetTemperature: targetTemperature,
      );

      // Queue command locally first (offline-first)
      await localDataSource.queueCommand(command);

      // Update status to in-progress
      final inProgressCommand = command.copyWith(
        status: CommandStatus.inProgress,
        sentAt: DateTime.now(),
      );
      await localDataSource.updateCommand(inProgressCommand);

      // Attempt to send command
      return await _sendCommandWithRetry(inProgressCommand);
    } catch (e) {
      if (e is OperationException) {
        return Left(_handleGraphQLException(e));
      }
      return Left(CacheFailure('Failed to send temperature command: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CommandRequest>>> getPendingCommands({
    required String deviceId,
  }) async {
    try {
      final commands = await localDataSource.getPendingCommands(
        deviceId: deviceId,
      );
      return Right(commands);
    } catch (e) {
      return Left(CacheFailure('Failed to get pending commands: $e'));
    }
  }

  @override
  Future<Either<Failure, CommandRequest>> retryCommand({
    required CommandRequest command,
  }) async {
    try {
      if (!command.canRetry) {
        return const Left(
          ValidationFailure('Command cannot be retried (max retries exceeded)'),
        );
      }

      // Update retry count and status
      final retryCommand = command.copyWith(
        status: CommandStatus.inProgress,
        sentAt: DateTime.now(),
        retryCount: command.retryCount + 1,
        errorMessage: null,
      );
      await localDataSource.updateCommand(retryCommand);

      // Attempt to send command
      return await _sendCommandWithRetry(retryCommand);
    } catch (e) {
      if (e is OperationException) {
        return Left(_handleGraphQLException(e));
      }
      return Left(ServerFailure('Failed to retry command: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelCommand({
    required String commandId,
  }) async {
    try {
      await localDataSource.removeCommand(commandId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to cancel command: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearOldCommands({
    Duration age = const Duration(hours: 24),
  }) async {
    try {
      await localDataSource.clearOldCommands(age: age);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear old commands: $e'));
    }
  }

  /// Send command with retry logic
  Future<Either<Failure, CommandRequest>> _sendCommandWithRetry(
    CommandRequest command,
  ) async {
    try {
      final response = await remoteDataSource.sendDeviceCommand(
        command: command,
      );

      // Update command with response
      final updatedCommand = response.updateCommand(command);
      await localDataSource.updateCommand(updatedCommand);

      if (response.success) {
        return Right(updatedCommand);
      } else {
        // Check if error is retryable
        if (response.isRetryable && command.canRetry) {
          // Don't automatically retry here - let caller decide
          return Left(ServerFailure(response.message ?? 'Command failed'));
        }

        return Left(ServerFailure(response.message ?? 'Command failed'));
      }
    } on OperationException catch (e) {
      // Mark command as failed
      final failedCommand = command.copyWith(
        status: CommandStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: 'GraphQL error: $e',
      );
      await localDataSource.updateCommand(failedCommand);

      return Left(_handleGraphQLException(e));
    } catch (e) {
      // Mark command as failed
      final failedCommand = command.copyWith(
        status: CommandStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: 'Unexpected error: $e',
      );
      await localDataSource.updateCommand(failedCommand);

      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  /// Handle GraphQL exception
  Failure _handleGraphQLException(OperationException exception) {
    // Check for network errors
    if (exception.linkException != null) {
      return const NetworkFailure('No internet connection');
    }

    // Check for GraphQL errors
    final graphqlErrors = exception.graphqlErrors;
    if (graphqlErrors.isNotEmpty) {
      final firstError = graphqlErrors.first;
      final message = firstError.message;

      // Check for device offline errors
      if (message.toLowerCase().contains('offline') ||
          message.toLowerCase().contains('unreachable')) {
        return ApiFailure(message, 503);
      }

      // Check for validation errors
      if (message.toLowerCase().contains('invalid') ||
          message.toLowerCase().contains('validation')) {
        return ValidationFailure(message);
      }

      return ApiFailure(message);
    }

    return const ApiFailure('GraphQL command failed');
  }
}
