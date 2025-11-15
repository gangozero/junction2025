/// Endpoint cache repository using Hive
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/logger.dart';
import '../config/endpoint_config.dart';

/// Repository for caching discovered endpoints
class EndpointRepository {
  static const String _boxName = 'endpoint_cache';
  static const String _configKey = 'current_config';
  static const String _timestampKey = 'last_updated';

  Box<dynamic>? _box;

  /// Initialize Hive box
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
      AppLogger.i('Endpoint cache initialized');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to initialize endpoint cache',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Save endpoint configuration
  Future<void> saveConfig(EndpointConfig config) async {
    try {
      await _box?.put(_configKey, config.toJson());
      await _box?.put(_timestampKey, DateTime.now().toIso8601String());
      AppLogger.i('Endpoint configuration saved to cache');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to save endpoint configuration',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get cached endpoint configuration
  EndpointConfig? getConfig() {
    try {
      final json = _box?.get(_configKey) as Map<dynamic, dynamic>?;
      if (json == null) {
        return null;
      }

      return EndpointConfig.fromJson(Map<String, dynamic>.from(json));
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to get cached endpoint configuration',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get timestamp of last configuration update
  DateTime? getLastUpdated() {
    try {
      final timestamp = _box?.get(_timestampKey) as String?;
      if (timestamp == null) {
        return null;
      }

      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Check if cached configuration is fresh (< 24 hours old)
  bool isCacheFresh() {
    final lastUpdated = getLastUpdated();
    if (lastUpdated == null) {
      return false;
    }

    final age = DateTime.now().difference(lastUpdated);
    return age.inHours < 24;
  }

  /// Clear cached configuration
  Future<void> clearCache() async {
    try {
      await _box?.clear();
      AppLogger.i('Endpoint cache cleared');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to clear endpoint cache',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Close the repository
  Future<void> close() async {
    await _box?.close();
  }
}
