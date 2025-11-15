/// Hive Storage Service for Harvia MSGA
///
/// Initializes and configures Hive for local data storage
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

/// Hive storage service
///
/// Manages Hive initialization, encryption, and box access
class HiveService {
  HiveService._();

  static bool _initialized = false;

  /// Initialize Hive with encryption
  ///
  /// Must be called before any Hive operations
  static Future<void> initialize() async {
    if (_initialized) {
      AppLogger.w('Hive already initialized');
      return;
    }

    try {
      AppLogger.i('Initializing Hive storage');

      // Initialize Hive for Flutter (sets proper storage path)
      await Hive.initFlutter();

      // Register adapters here (will be added in later tasks)
      // Example: Hive.registerAdapter(ScheduleAdapter());

      _initialized = true;
      AppLogger.i('Hive initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to initialize Hive',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheFailure('Failed to initialize local storage: $e');
    }
  }

  /// Open a Hive box
  ///
  /// Opens box with optional encryption key
  static Future<Box<T>> openBox<T>(
    String name, {
    List<int>? encryptionKey,
  }) async {
    if (!_initialized) {
      throw const CacheFailure(
        'Hive not initialized. Call HiveService.initialize() first.',
      );
    }

    try {
      AppLogger.d('Opening Hive box: $name');

      final box = await Hive.openBox<T>(
        name,
        encryptionCipher: encryptionKey != null
            ? HiveAesCipher(encryptionKey)
            : null,
      );

      AppLogger.d('Hive box opened: $name (${box.length} items)');
      return box;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to open Hive box: $name',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheFailure('Failed to open storage box: $e', CacheOperation.read);
    }
  }

  /// Get device cache box
  static Future<Box<Map<dynamic, dynamic>>> getDeviceBox() async {
    return openBox<Map<dynamic, dynamic>>(ApiConstants.deviceBoxName);
  }

  /// Get schedule cache box
  static Future<Box<Map<dynamic, dynamic>>> getScheduleBox() async {
    return openBox<Map<dynamic, dynamic>>(ApiConstants.scheduleBoxName);
  }

  /// Get event cache box (ring buffer)
  static Future<Box<Map<dynamic, dynamic>>> getEventBox() async {
    return openBox<Map<dynamic, dynamic>>(ApiConstants.eventBoxName);
  }

  /// Get command queue box
  static Future<Box<Map<dynamic, dynamic>>> getCommandQueueBox() async {
    return openBox<Map<dynamic, dynamic>>(ApiConstants.commandQueueBoxName);
  }

  /// Close a box
  static Future<void> closeBox(String name) async {
    try {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<dynamic>(name).close();
        AppLogger.d('Hive box closed: $name');
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to close Hive box: $name',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear a box (delete all data)
  static Future<void> clearBox(String name) async {
    try {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<dynamic>(name).clear();
        AppLogger.i('Hive box cleared: $name');
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to clear Hive box: $name',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheFailure('Failed to clear storage: $e', CacheOperation.clear);
    }
  }

  /// Delete a box completely
  static Future<void> deleteBox(String name) async {
    try {
      await Hive.deleteBoxFromDisk(name);
      AppLogger.i('Hive box deleted: $name');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to delete Hive box: $name',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheFailure('Failed to delete storage: $e', CacheOperation.delete);
    }
  }

  /// Clear all app data
  static Future<void> clearAllData() async {
    try {
      AppLogger.w('Clearing all Hive data');

      await Future.wait([
        clearBox(ApiConstants.deviceBoxName),
        clearBox(ApiConstants.scheduleBoxName),
        clearBox(ApiConstants.eventBoxName),
        clearBox(ApiConstants.commandQueueBoxName),
      ]);

      AppLogger.i('All Hive data cleared');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to clear all data', error: e, stackTrace: stackTrace);
      throw CacheFailure(
        'Failed to clear all storage: $e',
        CacheOperation.clear,
      );
    }
  }

  /// Close all boxes
  static Future<void> closeAll() async {
    try {
      await Hive.close();
      _initialized = false;
      AppLogger.i('All Hive boxes closed');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to close all boxes',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
