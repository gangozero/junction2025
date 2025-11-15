/// API Constants for Harvia Cloud Integration
///
/// Defines all endpoint URLs, configuration values, and constants
/// for connecting to the Harvia Cloud API services.
library;

/// Base URLs for Harvia Cloud API
class ApiConstants {
  ApiConstants._();

  // ============================================================================
  // ENVIRONMENT CONFIGURATION
  // ============================================================================

  /// Current environment (production, staging, development)
  /// TODO: Configure based on build flavor
  static const String environment = 'production';

  /// Enable debug logging for API calls
  static const bool enableApiLogging = true;

  // ============================================================================
  // BASE URLS
  // ============================================================================

  /// Base URL for REST API (Authentication)
  /// Used for: /auth/token, /auth/refresh, /auth/revoke
  static const String restBaseUrl = 'https://api.harvia.cloud';

  /// Base URL for GraphQL API (Device/Data/Events services)
  /// Used for: queries, mutations, subscriptions
  static const String graphqlBaseUrl = 'https://graphql.harvia.cloud';

  /// WebSocket URL for GraphQL subscriptions
  /// Used for: real-time device state, sensor data, events
  static const String graphqlWsUrl = 'wss://graphql.harvia.cloud';

  // ============================================================================
  // REST ENDPOINTS (Authentication Service)
  // ============================================================================

  /// POST /auth/token - Exchange credentials for access/refresh tokens
  static const String authTokenEndpoint = '/auth/token';

  /// POST /auth/refresh - Exchange refresh token for new access token
  static const String authRefreshEndpoint = '/auth/refresh';

  /// POST /auth/revoke - Invalidate refresh token (logout)
  static const String authRevokeEndpoint = '/auth/revoke';

  // ============================================================================
  // GRAPHQL OPERATIONS
  // ============================================================================

  /// GraphQL HTTP endpoint for queries and mutations
  static const String graphqlHttpPath = '/graphql';

  /// GraphQL WebSocket endpoint for subscriptions
  static const String graphqlWsPath = '/subscriptions';

  // ============================================================================
  // TIMEOUT CONFIGURATION
  // ============================================================================

  /// HTTP connection timeout (milliseconds)
  static const int connectionTimeout = 30000; // 30 seconds

  /// HTTP receive timeout (milliseconds)
  static const int receiveTimeout = 30000; // 30 seconds

  /// HTTP send timeout (milliseconds)
  static const int sendTimeout = 30000; // 30 seconds

  /// WebSocket ping interval (milliseconds)
  static const int wsPingInterval = 30000; // 30 seconds

  /// WebSocket reconnection delay (milliseconds)
  static const int wsReconnectDelay = 5000; // 5 seconds

  /// WebSocket maximum reconnection delay (seconds)
  static const int wsMaxReconnectDelay = 30; // 30 seconds

  /// Maximum reconnection attempts
  static const int maxReconnectAttempts = 5;

  // ============================================================================
  // CACHE CONFIGURATION
  // ============================================================================

  /// Token refresh threshold (refresh before expiry, in seconds)
  static const int tokenRefreshThreshold = 300; // 5 minutes

  /// Device state cache duration (milliseconds)
  static const int deviceCacheDuration = 60000; // 1 minute

  /// Event cache max size (ring buffer)
  static const int eventCacheMaxSize = 1000;

  // ============================================================================
  // HEADERS
  // ============================================================================

  /// Content-Type for REST requests
  static const String contentTypeJson = 'application/json';

  /// Accept header for REST requests
  static const String acceptJson = 'application/json';

  /// Authorization header prefix
  static const String authHeaderPrefix = 'Bearer';

  // ============================================================================
  // RETRY CONFIGURATION
  // ============================================================================

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Initial retry delay (milliseconds)
  static const int retryDelayMs = 1000;

  /// Retry delay multiplier (exponential backoff)
  static const double retryDelayMultiplier = 2.0;

  // ============================================================================
  // PLATFORM-SPECIFIC CONFIGURATION
  // ============================================================================

  /// Secure storage keys
  static const String accessTokenKey = 'harvia_access_token';
  static const String refreshTokenKey = 'harvia_refresh_token';
  static const String userIdKey = 'harvia_user_id';
  static const String sessionKey = 'harvia_session_key';

  /// Hive box names
  static const String deviceBoxName = 'devices';
  static const String scheduleBoxName = 'schedules';
  static const String eventBoxName = 'events';
  static const String commandQueueBoxName = 'command_queue';

  /// Notification channels (Android)
  static const String notificationChannelId = 'harvia_events';
  static const String notificationChannelName = 'Sauna Events';
  static const String notificationChannelDescription =
      'Notifications for sauna events and alerts';

  // ============================================================================
  // VALIDATION CONSTRAINTS
  // ============================================================================

  /// Temperature range (Celsius)
  /// Note: Actual ranges are model-specific; these are global limits
  static const double minTemperature = 40.0;
  static const double maxTemperature = 110.0;

  /// Humidity range (percentage)
  static const double minHumidity = 0.0;
  static const double maxHumidity = 100.0;

  /// Schedule constraints
  static const int maxSchedulesPerDevice = 20;
  static const int minScheduleIntervalMinutes = 30;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get full REST endpoint URL
  static String getRestUrl(String endpoint) {
    return '$restBaseUrl$endpoint';
  }

  /// Get full GraphQL HTTP URL
  static String getGraphqlHttpUrl() {
    return '$graphqlBaseUrl$graphqlHttpPath';
  }

  /// Get full GraphQL WebSocket URL
  static String getGraphqlWsUrl() {
    return '$graphqlWsUrl$graphqlWsPath';
  }

  /// Get authorization header value
  static String getAuthHeader(String token) {
    return '$authHeaderPrefix $token';
  }
}
