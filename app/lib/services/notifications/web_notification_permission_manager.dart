/// Web notification permission manager
///
/// Handles browser Notification API permission requests
library;

import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import '../../core/utils/logger.dart';

/// Web notification permission manager
///
/// Provides web-specific notification permission handling using browser APIs
class WebNotificationPermissionManager {
  static final WebNotificationPermissionManager _instance =
      WebNotificationPermissionManager._internal();
  factory WebNotificationPermissionManager() => _instance;
  WebNotificationPermissionManager._internal();

  /// Check if notifications are supported
  bool get isSupported {
    if (!kIsWeb) return false;
    return html.Notification.supported;
  }

  /// Get current permission status
  String get permissionStatus {
    if (!isSupported) return 'unsupported';
    return html.Notification.permission ?? 'default';
  }

  /// Check if permission is granted
  bool get hasPermission {
    return permissionStatus == 'granted';
  }

  /// Check if permission can be requested
  bool get canRequestPermission {
    final status = permissionStatus;
    return status == 'default' || status == 'denied';
  }

  /// Request notification permission
  ///
  /// Returns true if permission is granted
  Future<bool> requestPermission() async {
    if (!isSupported) {
      AppLogger.w('Web notifications not supported in this browser');
      return false;
    }

    if (hasPermission) {
      AppLogger.i('Web notifications already granted');
      return true;
    }

    if (permissionStatus == 'denied') {
      AppLogger.w(
        'Web notification permission previously denied. '
        'User must manually enable in browser settings.',
      );
      return false;
    }

    try {
      AppLogger.i('Requesting web notification permission');

      // Request permission from browser
      final permission = await html.Notification.requestPermission();

      final granted = permission == 'granted';

      AppLogger.i('Web notification permission: $permission');

      return granted;
    } catch (e) {
      AppLogger.e('Error requesting web notification permission', error: e);
      return false;
    }
  }

  /// Show a test notification
  ///
  /// Useful for verifying permissions work correctly
  void showTestNotification() {
    if (!hasPermission) {
      AppLogger.w('Cannot show test notification - no permission');
      return;
    }

    try {
      html.Notification(
        'Harvia Sauna Controller',
        body:
            'Notifications are working! You\'ll receive alerts for sauna events.',
        icon: '/icons/Icon-192.png',
      );

      AppLogger.i('Test notification sent');
    } catch (e) {
      AppLogger.e('Error showing test notification', error: e);
    }
  }

  /// Show a notification with custom options
  void showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
  }) {
    if (!hasPermission) {
      AppLogger.w('Cannot show notification - no permission');
      return;
    }

    try {
      html.Notification(
        title,
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
        tag: tag,
      );

      AppLogger.notification(title, body);
    } catch (e) {
      AppLogger.e('Error showing web notification', error: e);
    }
  }
}
