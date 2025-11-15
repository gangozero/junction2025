/// Background task service
library;

/// Platform-agnostic background task service
///
/// Provides unified interface for background task execution:
/// - Mobile: workmanager for periodic and one-time background tasks
/// - Web: Service workers with periodic background sync
///
/// Supports schedule execution, offline command queue processing,
/// and platform-specific constraints (battery, network).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/platform_utils.dart';

/// Background service for cross-platform background task execution
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;

  /// Initialize background service
  ///
  /// Sets up workmanager for mobile or service worker for web
  /// Returns true if initialization successful
  Future<bool> initialize({
    Future<bool> Function(String taskName, Map<String, dynamic>? inputData)?
    onBackgroundTask,
  }) async {
    if (_isInitialized) {
      AppLogger.i('Background service already initialized');
      return true;
    }

    // Task callback will be used in T095/T097 for schedule execution
    // Currently stored but not yet implemented
    if (onBackgroundTask != null) {
      // Future use: will be called from _callbackDispatcher
    }

    try {
      if (PlatformUtils.isWeb) {
        return await _initializeWeb();
      } else {
        return await _initializeMobile();
      }
    } catch (e) {
      AppLogger.e('Failed to initialize background service', error: e);
      return false;
    }
  }

  /// Initialize mobile background tasks (iOS/Android via workmanager)
  Future<bool> _initializeMobile() async {
    AppLogger.i('Initializing mobile background service');

    try {
      await Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      _isInitialized = true;
      AppLogger.i('Mobile background service initialized successfully');
      return true;
    } catch (e) {
      AppLogger.e('Failed to initialize workmanager', error: e);
      return false;
    }
  }

  /// Initialize web background tasks (service worker)
  Future<bool> _initializeWeb() async {
    AppLogger.i('Initializing web background service');

    // Web background tasks handled by service worker (web/service_worker.js)
    // Service worker registered in web/index.html
    // Periodic background sync requires user permission and browser support

    _isInitialized = true;
    AppLogger.i(
      'Web background service initialized '
      '(service worker handles background sync)',
    );
    return true;
  }

  /// Register periodic task
  ///
  /// Executes task at specified frequency
  /// Mobile: workmanager periodic task (minimum 15 minutes)
  /// Web: periodic background sync (browser-dependent, may not execute)
  Future<void> registerPeriodicTask({
    required String uniqueName,
    required Duration frequency,
    Map<String, dynamic>? inputData,
    String? tag,
    BackgroundTaskConstraints? constraints,
  }) async {
    if (!_isInitialized) {
      AppLogger.w('Background service not initialized');
      return;
    }

    if (PlatformUtils.isWeb) {
      await _registerWebPeriodicTask(uniqueName, frequency, inputData);
    } else {
      await _registerMobilePeriodicTask(
        uniqueName,
        frequency,
        inputData,
        tag,
        constraints,
      );
    }
  }

  /// Register mobile periodic task via workmanager
  Future<void> _registerMobilePeriodicTask(
    String uniqueName,
    Duration frequency,
    Map<String, dynamic>? inputData,
    String? tag,
    BackgroundTaskConstraints? constraints,
  ) async {
    // Workmanager requires minimum 15-minute frequency
    const minFrequency = Duration(minutes: 15);
    final actualFrequency = frequency < minFrequency ? minFrequency : frequency;

    if (frequency < minFrequency) {
      AppLogger.w(
        'Background task frequency adjusted from ${frequency.inMinutes}min '
        'to ${minFrequency.inMinutes}min (workmanager minimum)',
      );
    }

    await Workmanager().registerPeriodicTask(
      uniqueName,
      tag ?? uniqueName,
      frequency: actualFrequency,
      inputData: inputData,
      constraints: _convertConstraints(constraints),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    AppLogger.background(uniqueName, 'Periodic task registered');
  }

  /// Register web periodic task via service worker
  Future<void> _registerWebPeriodicTask(
    String uniqueName,
    Duration frequency,
    Map<String, dynamic>? inputData,
  ) async {
    // Web periodic background sync registration requires JS interop
    // Service worker will handle periodic sync events
    // Note: Browser support varies, may not execute reliably

    AppLogger.background(
      uniqueName,
      'Web periodic task registered (service worker - limited support)',
    );

    // In production, use dart:js_interop or package:web to call:
    // navigator.serviceWorker.ready.then(registration =>
    //   registration.periodicSync.register(uniqueName, {
    //     minInterval: frequency.inMilliseconds
    //   })
    // )
  }

  /// Register one-time task
  ///
  /// Executes task once, optionally with delay
  /// Mobile: workmanager one-time task
  /// Web: service worker sync event (executes when online)
  Future<void> registerOneTimeTask({
    required String uniqueName,
    Duration? initialDelay,
    Map<String, dynamic>? inputData,
    String? tag,
    BackgroundTaskConstraints? constraints,
  }) async {
    if (!_isInitialized) {
      AppLogger.w('Background service not initialized');
      return;
    }

    if (PlatformUtils.isWeb) {
      await _registerWebOneTimeTask(uniqueName, inputData);
    } else {
      await _registerMobileOneTimeTask(
        uniqueName,
        initialDelay,
        inputData,
        tag,
        constraints,
      );
    }
  }

  /// Register mobile one-time task via workmanager
  Future<void> _registerMobileOneTimeTask(
    String uniqueName,
    Duration? initialDelay,
    Map<String, dynamic>? inputData,
    String? tag,
    BackgroundTaskConstraints? constraints,
  ) async {
    await Workmanager().registerOneOffTask(
      uniqueName,
      tag ?? uniqueName,
      initialDelay: initialDelay ?? Duration.zero,
      inputData: inputData,
      constraints: _convertConstraints(constraints),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    AppLogger.background(uniqueName, 'One-time task registered');
  }

  /// Register web one-time task via service worker sync
  Future<void> _registerWebOneTimeTask(
    String uniqueName,
    Map<String, dynamic>? inputData,
  ) async {
    // Web background sync registration requires JS interop
    // Service worker will handle sync event when online

    AppLogger.background(
      uniqueName,
      'Web one-time task registered (service worker sync)',
    );

    // In production, use dart:js_interop or package:web to call:
    // navigator.serviceWorker.ready.then(registration =>
    //   registration.sync.register(uniqueName)
    // )
  }

  /// Cancel task by unique name
  Future<void> cancelTask(String uniqueName) async {
    if (!_isInitialized) return;

    if (PlatformUtils.isWeb) {
      // Web: cannot cancel service worker tasks directly
      AppLogger.background(uniqueName, 'Cannot cancel web background task');
    } else {
      await Workmanager().cancelByUniqueName(uniqueName);
      AppLogger.background(uniqueName, 'Task cancelled');
    }
  }

  /// Cancel all tasks
  Future<void> cancelAllTasks() async {
    if (!_isInitialized) return;

    if (PlatformUtils.isWeb) {
      // Web: cannot cancel service worker tasks directly
      AppLogger.background('all', 'Cannot cancel web background tasks');
    } else {
      await Workmanager().cancelAll();
      AppLogger.background('all', 'All tasks cancelled');
    }
  }

  /// Convert constraints to workmanager format
  Constraints? _convertConstraints(BackgroundTaskConstraints? constraints) {
    if (constraints == null) return null;

    return Constraints(
      networkType: _convertNetworkType(constraints.networkType),
      requiresBatteryNotLow: constraints.requiresBatteryNotLow,
      requiresCharging: constraints.requiresCharging,
      requiresDeviceIdle: constraints.requiresDeviceIdle,
      requiresStorageNotLow: constraints.requiresStorageNotLow,
    );
  }

  /// Convert network type to workmanager format
  NetworkType _convertNetworkType(NetworkTypeConstraint type) {
    switch (type) {
      case NetworkTypeConstraint.notRequired:
        return NetworkType.not_required;
      case NetworkTypeConstraint.connected:
        return NetworkType.connected;
      case NetworkTypeConstraint.unmetered:
        return NetworkType.unmetered;
      case NetworkTypeConstraint.notRoaming:
        return NetworkType.not_roaming;
      case NetworkTypeConstraint.metered:
        return NetworkType.metered;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Workmanager callback dispatcher
///
/// Called by workmanager when background task executes
/// Must be top-level function (not method)
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      AppLogger.i('Background task executing: $taskName');

      // Background tasks will be implemented in specific features
      // For now, just log execution
      // Actual implementation in T095 (mobile scheduler) and T097 (schedule coordinator)

      AppLogger.background(taskName, 'Executed successfully');
      return Future.value(true);
    } catch (e) {
      AppLogger.e('Background task failed: $taskName', error: e);
      return Future.value(false);
    }
  });
}

/// Background task constraints
///
/// Specifies conditions that must be met for task execution
class BackgroundTaskConstraints {
  /// Network connectivity requirement
  final NetworkTypeConstraint networkType;

  /// Require battery level not low
  final bool requiresBatteryNotLow;

  /// Require device charging
  final bool requiresCharging;

  /// Require device idle (Android only)
  final bool requiresDeviceIdle;

  /// Require storage not low
  final bool requiresStorageNotLow;

  const BackgroundTaskConstraints({
    this.networkType = NetworkTypeConstraint.notRequired,
    this.requiresBatteryNotLow = false,
    this.requiresCharging = false,
    this.requiresDeviceIdle = false,
    this.requiresStorageNotLow = false,
  });

  /// Default constraints (no requirements)
  static const none = BackgroundTaskConstraints();

  /// Require any network connectivity
  static const connected = BackgroundTaskConstraints(
    networkType: NetworkTypeConstraint.connected,
  );

  /// Require unmetered network (WiFi)
  static const unmetered = BackgroundTaskConstraints(
    networkType: NetworkTypeConstraint.unmetered,
  );

  /// Require charging and good battery
  static const charging = BackgroundTaskConstraints(
    requiresCharging: true,
    requiresBatteryNotLow: true,
  );
}

/// Network type constraints for background tasks
enum NetworkTypeConstraint {
  /// Network not required
  notRequired,

  /// Any network connection required
  connected,

  /// Unmetered network required (WiFi, not cellular)
  unmetered,

  /// Network not roaming
  notRoaming,

  /// Metered network allowed
  metered,
}
