/// Platform Detection Utility for Harvia MSGA
///
/// Provides utilities to detect platform and adjust features accordingly
library;

import 'package:flutter/foundation.dart';

/// Platform detection and feature flags
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile (iOS or Android)
  static bool get isMobile => !kIsWeb;

  /// Check if running on iOS
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Check if running on Android
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Check if background tasks are supported
  ///
  /// Mobile: Uses workmanager
  /// Web: Uses service worker (limited support)
  static bool get supportsBackgroundTasks => isMobile;

  /// Check if native notifications are supported
  ///
  /// Mobile: flutter_local_notifications (full support)
  /// Web: Browser notifications (requires permission)
  static bool get supportsNotifications => true;

  /// Check if secure storage uses native keychain/keystore
  ///
  /// Mobile: Uses platform keychain/keystore
  /// Web: Uses encrypted IndexedDB
  static bool get hasNativeSecureStorage => isMobile;

  /// Check if exact alarm scheduling is supported
  ///
  /// Mobile: Android 12+ or iOS (full support)
  /// Web: Limited via service worker periodic sync
  static bool get supportsExactAlarms => isMobile;

  /// Get platform name for logging/analytics
  static String get platformName {
    if (isWeb) return 'Web';
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    return 'Unknown';
  }

  /// Get storage type description
  static String get storageType {
    if (isIOS) return 'iOS Keychain';
    if (isAndroid) return 'Android Keystore';
    if (isWeb) return 'Encrypted IndexedDB';
    return 'Unknown';
  }

  /// Get background task type description
  static String get backgroundTaskType {
    if (isMobile) return 'Workmanager';
    if (isWeb) return 'Service Worker';
    return 'None';
  }

  /// Get notification type description
  static String get notificationType {
    if (isMobile) return 'Native Push';
    if (isWeb) return 'Browser Notifications';
    return 'None';
  }
}
