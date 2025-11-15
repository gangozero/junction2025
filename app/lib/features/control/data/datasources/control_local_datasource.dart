/// Control local data source
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/command_request.dart';

/// Control local data source
///
/// Manages offline command queue using Hive
class ControlLocalDataSource {
  static const String _boxName = 'command_queue';
  late final Box<Map<dynamic, dynamic>> _box;

  ControlLocalDataSource();

  /// Initialize Hive box
  Future<void> init() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  /// Queue command for offline operation
  Future<void> queueCommand(CommandRequest command) async {
    try {
      await _box.put(command.commandId, _commandToMap(command));
    } catch (e) {
      throw Exception('Failed to queue command: $e');
    }
  }

  /// Get pending commands for a device
  Future<List<CommandRequest>> getPendingCommands({
    required String deviceId,
  }) async {
    try {
      final commands = <CommandRequest>[];

      for (final entry in _box.toMap().entries) {
        final commandMap = entry.value;
        final command = _commandFromMap(commandMap);

        if (command.deviceId == deviceId &&
            command.status == CommandStatus.pending) {
          commands.add(command);
        }
      }

      // Sort by requestedAt (oldest first)
      commands.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));

      return commands;
    } catch (e) {
      throw Exception('Failed to get pending commands: $e');
    }
  }

  /// Get all pending commands across all devices
  Future<List<CommandRequest>> getAllPendingCommands() async {
    try {
      final commands = <CommandRequest>[];

      for (final entry in _box.toMap().entries) {
        final commandMap = entry.value;
        final command = _commandFromMap(commandMap);

        if (command.status == CommandStatus.pending) {
          commands.add(command);
        }
      }

      // Sort by requestedAt (oldest first)
      commands.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));

      return commands;
    } catch (e) {
      throw Exception('Failed to get all pending commands: $e');
    }
  }

  /// Update command status
  Future<void> updateCommand(CommandRequest command) async {
    try {
      await _box.put(command.commandId, _commandToMap(command));
    } catch (e) {
      throw Exception('Failed to update command: $e');
    }
  }

  /// Remove command from queue
  Future<void> removeCommand(String commandId) async {
    try {
      await _box.delete(commandId);
    } catch (e) {
      throw Exception('Failed to remove command: $e');
    }
  }

  /// Clear completed commands older than specified duration
  Future<void> clearOldCommands({
    Duration age = const Duration(hours: 24),
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(age);
      final keysToDelete = <String>[];

      for (final entry in _box.toMap().entries) {
        final commandMap = entry.value;
        final command = _commandFromMap(commandMap);

        // Delete if completed/failed and older than cutoff
        if (command.status.isTerminal &&
            command.completedAt != null &&
            command.completedAt!.isBefore(cutoffTime)) {
          keysToDelete.add(command.commandId);
        }
      }

      await _box.deleteAll(keysToDelete);
    } catch (e) {
      throw Exception('Failed to clear old commands: $e');
    }
  }

  /// Convert command to map for storage
  Map<String, dynamic> _commandToMap(CommandRequest command) {
    return {
      'commandId': command.commandId,
      'deviceId': command.deviceId,
      'type': command.type.name,
      'parameters': command.parameters,
      'status': command.status.name,
      'requestedAt': command.requestedAt.toIso8601String(),
      'sentAt': command.sentAt?.toIso8601String(),
      'completedAt': command.completedAt?.toIso8601String(),
      'errorMessage': command.errorMessage,
      'retryCount': command.retryCount,
    };
  }

  /// Convert map to command entity
  CommandRequest _commandFromMap(Map<dynamic, dynamic> map) {
    return CommandRequest(
      commandId: map['commandId'] as String,
      deviceId: map['deviceId'] as String,
      type: CommandType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => CommandType.unknown,
      ),
      parameters: Map<String, dynamic>.from(map['parameters'] as Map? ?? {}),
      status: CommandStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => CommandStatus.pending,
      ),
      requestedAt: DateTime.parse(map['requestedAt'] as String),
      sentAt: map['sentAt'] != null
          ? DateTime.parse(map['sentAt'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      errorMessage: map['errorMessage'] as String?,
      retryCount: map['retryCount'] as int? ?? 0,
    );
  }
}
