/// API Constants for Harvia Cloud Integration
///
/// Defines all endpoint URLs, configuration values, and constants
/// for connecting to the Harvia Cloud API services.
///
/// **IMPORTANT**: Endpoints are discovered dynamically at runtime via
/// https://prod.api.harvia.io/endpoints service discovery endpoint.
/// These constants serve as fallbacks and documentation.
library;

/// Base URLs for Harvia Cloud API
class ApiConstants {
  ApiConstants._();

  // ============================================================================
  // SERVICE DISCOVERY
  // ============================================================================

  /// Service discovery endpoint (always fetched first)
  /// Returns current REST, GraphQL, and IoT endpoints
  static const String serviceDiscoveryUrl =
      'https://prod.api.harvia.io/endpoints';

  // ============================================================================
  // ENVIRONMENT CONFIGURATION
  // ============================================================================

  /// Current environment (production, staging, development)
  static const String environment = 'production';

  /// AWS Region
  static const String awsRegion = 'eu-central-1';

  /// Cognito User Pool ID
  static const String cognitoUserPoolId = 'eu-central-1_PYox3qeLn';

  /// Cognito Identity Pool ID
  static const String cognitoIdentityPoolId =
      'eu-central-1:c6b64717-a29e-4695-8ce4-97c93470da8a';

  /// Enable debug logging for API calls
  static const bool enableApiLogging = true;

  // ============================================================================
  // REST API BASE URLS (fetched from service discovery)
  // ============================================================================

  /// REST API - Generics (Authentication & Users)
  /// Used for: authentication, user management, generic operations
  static const String restGenericsBaseUrl =
      'https://zft3sdx910.execute-api.eu-central-1.amazonaws.com/prod';

  /// REST API - Device (Controller Configuration & Shadow State)
  /// Used for: device configuration, shadow state, device management
  static const String restDeviceBaseUrl =
      'https://ap754v98f8.execute-api.eu-central-1.amazonaws.com/prod';

  /// REST API - Data (Latest State & Events)
  /// Used for: latest sensor data, device state, events
  static const String restDataBaseUrl =
      'https://u4830dkpl0.execute-api.eu-central-1.amazonaws.com/prod';

  /// REST API - Users
  /// Used for: user profile, preferences, settings
  static const String restUsersBaseUrl =
      'https://c3jzg90xli.execute-api.eu-central-1.amazonaws.com/prod';

  // ============================================================================
  // GRAPHQL ENDPOINTS (fetched from service discovery)
  // ============================================================================

  /// GraphQL - Data Service (Sensor Data & State)
  /// HTTPS endpoint for queries/mutations
  static const String graphqlDataHttpUrl =
      'https://b6ypjrrojzfuleunmrsysp7aya.appsync-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Data Service (Sensor Data & State)
  /// WebSocket endpoint for real-time subscriptions
  static const String graphqlDataWsUrl =
      'wss://b6ypjrrojzfuleunmrsysp7aya.appsync-realtime-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Device Service (Controller Config & Commands)
  /// HTTPS endpoint for queries/mutations
  static const String graphqlDeviceHttpUrl =
      'https://6lhlukqhbzefnhad2qdyg2lffm.appsync-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Device Service (Controller Config & Commands)
  /// WebSocket endpoint for real-time subscriptions
  static const String graphqlDeviceWsUrl =
      'wss://6lhlukqhbzefnhad2qdyg2lffm.appsync-realtime-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Events Service (Event History & Notifications)
  /// HTTPS endpoint for queries/mutations
  static const String graphqlEventsHttpUrl =
      'https://ykn3dsmrrvc47lnzh5vowxevb4.appsync-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Events Service (Event History & Notifications)
  /// WebSocket endpoint for real-time subscriptions
  static const String graphqlEventsWsUrl =
      'wss://ykn3dsmrrvc47lnzh5vowxevb4.appsync-realtime-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Users Service (User Profiles & Preferences)
  /// HTTPS endpoint for queries/mutations
  static const String graphqlUsersHttpUrl =
      'https://qizruaso4naexbnzmmp2cokenq.appsync-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Users Service (User Profiles & Preferences)
  /// WebSocket endpoint for real-time subscriptions
  static const String graphqlUsersWsUrl =
      'wss://qizruaso4naexbnzmmp2cokenq.appsync-realtime-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Stats Service (Analytics & Statistics)
  /// HTTPS endpoint for queries/mutations
  static const String graphqlStatsHttpUrl =
      'https://2y6n4pgr6nbmddojwqrsrxhfnq.appsync-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Stats Service (Analytics & Statistics)
  /// WebSocket endpoint for real-time subscriptions
  static const String graphqlStatsWsUrl =
      'wss://2y6n4pgr6nbmddojwqrsrxhfnq.appsync-realtime-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Payment Service (Subscriptions & Purchases)
  /// HTTPS endpoint for queries/mutations
  static const String graphqlPaymentHttpUrl =
      'https://2bmloen445dojlgqfnw7b4kabu.appsync-api.eu-central-1.amazonaws.com/graphql';

  /// GraphQL - Payment Service (Subscriptions & Purchases)
  /// WebSocket endpoint for real-time subscriptions
  static const String graphqlPaymentWsUrl =
      'wss://2bmloen445dojlgqfnw7b4kabu.appsync-realtime-api.eu-central-1.amazonaws.com/graphql';

  // ============================================================================
  // IOT CORE CONFIGURATION
  // ============================================================================

  /// AWS IoT Core endpoint for device telemetry
  static const String iotCoreEndpoint =
      'ab4fm8yv2cf3g-ats.iot.eu-central-1.amazonaws.com';

  /// IoT Core credentials endpoint
  static const String iotCoreCredentialsEndpoint =
      'c9d0zb4dt5fpm.credentials.iot.eu-central-1.amazonaws.com';

  // ============================================================================
  // DEPRECATED - Legacy Base URLs (kept for reference, use service-specific URLs above)
  // ============================================================================

  /// @deprecated Use service-specific REST URLs instead
  static const String restBaseUrl = restGenericsBaseUrl;

  /// @deprecated Use graphqlDeviceHttpUrl or graphqlDataHttpUrl instead
  static const String graphqlBaseUrl = graphqlDeviceHttpUrl;

  /// @deprecated Use graphqlDeviceWsUrl or graphqlDataWsUrl instead
  static const String graphqlWsUrl = graphqlDeviceWsUrl;

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
  static const String idTokenKey = 'harvia_id_token';
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
    // URL already includes /graphql path from service discovery
    return graphqlBaseUrl;
  }

  /// Get full GraphQL WebSocket URL
  static String getGraphqlWsUrl() {
    // URL already includes /graphql path from service discovery
    return graphqlWsUrl;
  }

  /// Get authorization header value
  static String getAuthHeader(String token) {
    return '$authHeaderPrefix $token';
  }
}
