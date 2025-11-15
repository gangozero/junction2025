/// Offline sync service
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';
import '../../features/control/data/datasources/control_local_datasource.dart';
import '../../features/control/domain/entities/command_request.dart';
import '../../features/control/domain/repositories/control_repository.dart';
import '../../features/events/data/datasources/events_local_datasource.dart';
import '../../features/events/domain/repositories/events_repository.dart';

/// Offline sync service
///
/// Coordinates syncing of offline data when network becomes available:
/// - Power commands
/// - Temperature settings
/// - Event acknowledgments
///
/// Constitution Principle II (Offline-First Architecture) compliance.
class OfflineSyncService {
  final ControlLocalDataSource _controlLocalDataSource;
  final ControlRepository _controlRepository;
  final EventsLocalDataSource _eventsLocalDataSource;
  final EventsRepository _eventsRepository;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isOnline = false;

  OfflineSyncService({
    required ControlLocalDataSource controlLocalDataSource,
    required ControlRepository controlRepository,
    required EventsLocalDataSource eventsLocalDataSource,
    required EventsRepository eventsRepository,
    Connectivity? connectivity,
  }) : _controlLocalDataSource = controlLocalDataSource,
       _controlRepository = controlRepository,
       _eventsLocalDataSource = eventsLocalDataSource,
       _eventsRepository = eventsRepository,
       _connectivity = connectivity ?? Connectivity();

  /// Initialize sync service
  ///
  /// Sets up connectivity monitoring and triggers initial sync if online.
  Future<void> init() async {
    AppLogger.i('Initializing offline sync service');

    // Check initial connectivity
    final connectivityResults = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(connectivityResults);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Trigger initial sync if online
    if (_isOnline) {
      unawaited(syncAll());
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _isConnected(results);

    AppLogger.i(
      'Connectivity changed: wasOnline=$wasOnline isOnline=$_isOnline results=${results.map((r) => r.name).toList()}',
    );

    // Trigger sync when coming back online
    if (!wasOnline && _isOnline) {
      AppLogger.i('Network restored - triggering sync');
      unawaited(syncAll());
    }
  }

  /// Check if connected based on connectivity results
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }

  /// Sync all pending offline data
  ///
  /// Returns true if sync was successful, false if already syncing or offline.
  Future<bool> syncAll() async {
    if (_isSyncing) {
      AppLogger.w('Sync already in progress');
      return false;
    }

    if (!_isOnline) {
      AppLogger.w('Cannot sync while offline');
      return false;
    }

    _isSyncing = true;
    AppLogger.i('Starting offline sync');

    try {
      // Sync pending commands
      await _syncPendingCommands();

      // Sync pending event acknowledgments
      await _syncPendingAcknowledgments();

      // Clean up old completed commands
      await _controlLocalDataSource.clearOldCommands();

      AppLogger.i('Offline sync completed successfully');
      return true;
    } catch (e) {
      AppLogger.e('Offline sync failed', error: e);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync pending commands to server
  Future<void> _syncPendingCommands() async {
    try {
      final pendingCommands = await _controlLocalDataSource
          .getAllPendingCommands();

      if (pendingCommands.isEmpty) {
        AppLogger.i('No pending commands to sync');
        return;
      }

      AppLogger.i('Syncing ${pendingCommands.length} pending commands');

      for (final command in pendingCommands) {
        try {
          // Send command based on type
          final result = await _sendCommand(command);

          result.fold(
            (Failure failure) {
              // Update command status to failed
              final updatedCommand = command.copyWith(
                status: CommandStatus.failed,
                errorMessage: failure.toString(),
                completedAt: DateTime.now(),
              );
              unawaited(_controlLocalDataSource.updateCommand(updatedCommand));
              AppLogger.w('Command sync failed: $failure');
            },
            (CommandRequest success) {
              // Remove successfully sent command
              unawaited(
                _controlLocalDataSource.removeCommand(command.commandId),
              );
              AppLogger.i('Command synced successfully: ${command.commandId}');
            },
          );
        } catch (e) {
          AppLogger.e('Failed to sync command ${command.commandId}', error: e);
          // Continue with next command
        }
      }
    } catch (e) {
      AppLogger.e('Failed to sync pending commands', error: e);
      rethrow;
    }
  }

  /// Send individual command based on type
  Future<dynamic> _sendCommand(CommandRequest command) async {
    switch (command.type) {
      case CommandType.powerOn:
      case CommandType.powerOff:
        return _controlRepository.sendPowerCommand(
          deviceId: command.deviceId,
          powerOn: command.type == CommandType.powerOn,
        );

      case CommandType.setTemperature:
        final targetTemp = command.parameters['targetTemperature'] as int?;
        if (targetTemp == null) {
          throw Exception('Missing targetTemperature in command parameters');
        }
        return _controlRepository.sendTemperatureCommand(
          deviceId: command.deviceId,
          targetTemperature: targetTemp.toDouble(),
        );

      case CommandType.unknown:
        throw Exception('Unknown command type: ${command.type}');
    }
  }

  /// Sync pending event acknowledgments
  Future<void> _syncPendingAcknowledgments() async {
    try {
      final pendingAcks = await _eventsLocalDataSource
          .getPendingAcknowledgments();

      if (pendingAcks.isEmpty) {
        AppLogger.i('No pending acknowledgments to sync');
        return;
      }

      AppLogger.i('Syncing ${pendingAcks.length} pending acknowledgments');

      for (final eventId in pendingAcks) {
        try {
          final result = await _eventsRepository.acknowledgeEvent(eventId);

          result.fold(
            (Failure failure) {
              AppLogger.w('Acknowledgment sync failed for $eventId: $failure');
              // Keep in pending queue for retry
            },
            (void success) {
              // Remove from pending queue
              unawaited(
                _eventsLocalDataSource.removePendingAcknowledgment(eventId),
              );
              AppLogger.i('Acknowledgment synced successfully: $eventId');
            },
          );
        } catch (e) {
          AppLogger.e('Failed to sync acknowledgment for $eventId', error: e);
          // Continue with next acknowledgment
        }
      }
    } catch (e) {
      AppLogger.e('Failed to sync pending acknowledgments', error: e);
      rethrow;
    }
  }

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Get sync status
  bool get isSyncing => _isSyncing;
}

/// Helper to avoid unawaited_futures warnings
void unawaited(Future<void> future) {}
