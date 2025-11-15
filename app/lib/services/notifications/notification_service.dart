/// Notification service for cross-platform local notifications
library;

/// Platform-agnostic notification service
///
/// Provides unified interface for local notifications across platforms:
/// - Mobile: flutter_local_notifications (iOS/Android native)
/// - Web: Browser Notification API with permission handling
///
/// Supports foreground/background notifications, custom sounds, actions,
/// and graceful degradation when permissions denied.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/platform_utils.dart';
import 'web_notification_permission_manager.dart'
    if (dart.library.io) '../../core/utils/stub_web_manager.dart';

/// Notification service for cross-platform local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  bool _hasPermission = false;

  /// Notification action callback
  /// Called when user taps notification or notification action button
  void Function(String? payload)? _onNotificationTap;

  /// Initialize notification service
  ///
  /// Requests permissions and sets up notification channels
  /// Returns true if initialization successful and permissions granted
  Future<bool> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (_isInitialized) {
      AppLogger.i('Notification service already initialized');
      return _hasPermission;
    }

    _onNotificationTap = onNotificationTap;

    try {
      if (PlatformUtils.isWeb) {
        return await _initializeWeb();
      } else {
        return await _initializeMobile();
      }
    } catch (e) {
      AppLogger.e('Failed to initialize notification service', error: e);
      return false;
    }
  }

  /// Initialize mobile notifications (iOS/Android)
  Future<bool> _initializeMobile() async {
    AppLogger.i('Initializing mobile notifications');

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _flutterLocalNotificationsPlugin!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    if (initialized == true) {
      // Request permissions
      _hasPermission = await requestPermissions();
      _isInitialized = true;

      // Create Android notification channels
      if (PlatformUtils.isAndroid) {
        await _createAndroidNotificationChannels();
      }

      AppLogger.i('Mobile notifications initialized successfully');
      return _hasPermission;
    }

    AppLogger.w('Failed to initialize mobile notifications');
    return false;
  }

  /// Initialize web notifications (Browser Notification API)
  Future<bool> _initializeWeb() async {
    AppLogger.i('Initializing web notifications');

    // Check if browser supports notifications
    if (!kIsWeb) {
      AppLogger.w('Not running on web platform');
      return false;
    }

    // Request permission via browser API
    _hasPermission = await requestPermissions();
    _isInitialized = true;

    AppLogger.i('Web notifications initialized, permission: $_hasPermission');
    return _hasPermission;
  }

  /// Create Android notification channels
  Future<void> _createAndroidNotificationChannels() async {
    if (_flutterLocalNotificationsPlugin == null) return;

    // High priority channel for critical alerts (errors, warnings)
    const highPriorityChannel = AndroidNotificationChannel(
      'sauna_alerts',
      'Sauna Alerts',
      description: 'Critical sauna alerts and warnings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Default channel for general notifications
    const defaultChannel = AndroidNotificationChannel(
      'sauna_notifications',
      'Sauna Notifications',
      description: 'General sauna status notifications',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Low priority channel for background updates
    const lowPriorityChannel = AndroidNotificationChannel(
      'sauna_updates',
      'Sauna Updates',
      description: 'Background sauna status updates',
      importance: Importance.low,
    );

    // Schedule reminders channel
    const scheduleChannel = AndroidNotificationChannel(
      'sauna_schedules',
      'Schedule Reminders',
      description: 'Heating schedule reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(highPriorityChannel);

    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(defaultChannel);

    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(lowPriorityChannel);

    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(scheduleChannel);

    AppLogger.i('Android notification channels created');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (PlatformUtils.isWeb) {
      return _requestWebPermissions();
    } else if (PlatformUtils.isIOS) {
      return _requestIOSPermissions();
    } else if (PlatformUtils.isAndroid) {
      return _requestAndroidPermissions();
    }
    return false;
  }

  /// Request iOS notification permissions
  Future<bool> _requestIOSPermissions() async {
    final permitted = await _flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    AppLogger.i('iOS notification permissions: $permitted');
    return permitted ?? false;
  }

  /// Request Android notification permissions (Android 13+)
  Future<bool> _requestAndroidPermissions() async {
    final permitted = await _flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    AppLogger.i('Android notification permissions: $permitted');
    return permitted ?? true; // Android <13 doesn't require runtime permission
  }

  /// Request web notification permissions
  Future<bool> _requestWebPermissions() async {
    if (!kIsWeb) {
      AppLogger.w('Not running on web platform');
      return false;
    }

    try {
      final webManager = WebNotificationPermissionManager();

      if (!webManager.isSupported) {
        AppLogger.w('Browser does not support notifications');
        return false;
      }

      if (webManager.hasPermission) {
        AppLogger.i('Web notifications already permitted');
        return true;
      }

      AppLogger.i('Requesting web notification permission');
      final granted = await webManager.requestPermission();

      AppLogger.i('Web notification permission: $granted');
      return granted;
    } catch (e) {
      AppLogger.e('Error requesting web permissions', error: e);
      return false;
    }
  }

  /// Show notification
  ///
  /// [id] - Unique notification ID (use same ID to update existing notification)
  /// [title] - Notification title
  /// [body] - Notification body text
  /// [payload] - Optional data passed to tap callback
  /// [priority] - Notification priority (high, default, low)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
  }) async {
    if (!_isInitialized) {
      AppLogger.w('Notification service not initialized');
      return;
    }

    if (!_hasPermission) {
      AppLogger.w('No notification permissions, skipping notification');
      return;
    }

    try {
      if (PlatformUtils.isWeb) {
        await _showWebNotification(id, title, body, payload);
      } else {
        await _showMobileNotification(id, title, body, payload, priority);
      }
    } catch (e) {
      AppLogger.e('Failed to show notification', error: e);
    }
  }

  /// Show mobile notification
  Future<void> _showMobileNotification(
    int id,
    String title,
    String body,
    String? payload,
    NotificationPriority priority,
  ) async {
    final channelId = _getChannelId(priority);
    final channelName = _getChannelName(priority);

    const androidDetails = AndroidNotificationDetails(
      'sauna_notifications', // Will be overridden by channelId
      'Sauna Notifications', // Will be overridden by channelName
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails.copyWith(
        channelId: channelId,
        channelName: channelName,
        importance: _getAndroidImportance(priority),
        priority: _getAndroidPriority(priority),
      ),
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin?.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    AppLogger.notification(title, body);
  }

  /// Show web notification
  Future<void> _showWebNotification(
    int id,
    String title,
    String body,
    String? payload,
  ) async {
    // Web notification requires JS interop
    // For now, log that web notification would be shown
    AppLogger.notification(title, '$body (web - requires JS interop)');

    // In production, use dart:js_interop or package:web to call:
    // new Notification(title, { body: body, data: payload })
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized || _flutterLocalNotificationsPlugin == null) return;

    await _flutterLocalNotificationsPlugin!.cancel(id);
    AppLogger.i('Notification cancelled: $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized || _flutterLocalNotificationsPlugin == null) return;

    await _flutterLocalNotificationsPlugin!.cancelAll();
    AppLogger.i('All notifications cancelled');
  }

  /// Schedule notification for future delivery
  ///
  /// Note: Requires timezone package and additional setup
  /// For scheduling, consider using workmanager for reliable background execution
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Scheduled notifications require timezone setup
    // Implementation deferred to T103 (schedule reminders)
    AppLogger.i('Schedule notification placeholder (implement in T103)');
  }

  // ============================================================================
  // Callback handlers
  // ============================================================================

  /// Handle notification tap on iOS (foreground)
  Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    AppLogger.i('iOS notification received in foreground: $id');
    _onNotificationTap?.call(payload);
  }

  /// Handle notification tap (Android/iOS background/foreground)
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    AppLogger.i(
      'Notification tapped: ${response.id}, payload: ${response.payload}',
    );
    _onNotificationTap?.call(response.payload);
  }

  // ============================================================================
  // Helper methods
  // ============================================================================

  String _getChannelId(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'sauna_alerts';
      case NotificationPriority.low:
        return 'sauna_updates';
      case NotificationPriority.schedule:
        return 'sauna_schedules';
      case NotificationPriority.defaultPriority:
        return 'sauna_notifications';
    }
  }

  String _getChannelName(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'Sauna Alerts';
      case NotificationPriority.low:
        return 'Sauna Updates';
      case NotificationPriority.schedule:
        return 'Schedule Reminders';
      case NotificationPriority.defaultPriority:
        return 'Sauna Notifications';
    }
  }

  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
      case NotificationPriority.schedule:
        return Importance.high;
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.defaultPriority:
        return Importance.defaultImportance;
    }
  }

  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
      case NotificationPriority.schedule:
        return Priority.high;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
    }
  }

  /// Check if notifications are enabled
  bool get hasPermission => _hasPermission;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Notification priority levels
enum NotificationPriority {
  /// High priority - critical alerts, errors
  high,

  /// Default priority - general notifications
  defaultPriority,

  /// Low priority - background updates
  low,

  /// Schedule priority - heating schedule reminders
  schedule,
}

/// Extension for AndroidNotificationDetails copying
extension AndroidNotificationDetailsCopy on AndroidNotificationDetails {
  AndroidNotificationDetails copyWith({
    String? channelId,
    String? channelName,
    Importance? importance,
    Priority? priority,
  }) {
    return AndroidNotificationDetails(
      channelId ?? this.channelId,
      channelName ?? this.channelName,
      importance: importance ?? this.importance,
      priority: priority ?? this.priority,
      icon: icon,
      playSound: playSound,
      enableVibration: enableVibration,
    );
  }
}
