# API Integration Guide

This document provides comprehensive guidance for integrating with the Harvia Sauna Controller API from the Flutter mobile application.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [GraphQL Integration](#graphql-integration)
- [REST Integration](#rest-integration)
- [WebSocket Subscriptions](#websocket-subscriptions)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Best Practices](#best-practices)
- [Code Examples](#code-examples)

## Overview

The Harvia API provides three types of endpoints:

1. **REST API**: Authentication and simple synchronous operations
2. **GraphQL HTTPS**: Query and mutation operations for devices, events, and data
3. **GraphQL WebSocket**: Real-time subscriptions for device state changes

### Base URL

Production: `https://prod.api.harvia.io`

### Dynamic Endpoint Discovery

Endpoints are dynamically retrieved on app startup:

```dart
GET /endpoints
```

Response:
```json
{
  "endpoints": {
    "RestApi": {
      "generics": { "https": "https://prod.api.harvia.io/rest/generics" },
      "device": { "https": "https://prod.api.harvia.io/rest/device" },
      "data": { "https": "https://prod.api.harvia.io/rest/data" }
    },
    "GraphQL": {
      "device": {
        "https": "https://prod.api.harvia.io/graphql/device",
        "wss": "wss://prod.api.harvia.io/graphql/device"
      },
      "data": {
        "https": "https://prod.api.harvia.io/graphql/data",
        "wss": "wss://prod.api.harvia.io/graphql/data"
      },
      "events": {
        "https": "https://prod.api.harvia.io/graphql/events",
        "wss": "wss://prod.api.harvia.io/graphql/events"
      }
    }
  }
}
```

## Authentication

### Flow Overview

```
1. User enters credentials
   ↓
2. POST /auth/token
   ↓
3. Receive: idToken, accessToken, refreshToken, expiresIn
   ↓
4. Store tokens in encrypted Hive box
   ↓
5. Use idToken in Authorization header for API requests
   ↓
6. Auto-refresh 5 minutes before expiry
```

### Login Request

**Endpoint**: `POST /auth/token`

```dart
// Request
final response = await dio.post(
  '${ApiConstants.baseUrl}/auth/token',
  data: {
    'username': email,
    'password': password,
  },
);

// Response
{
  "idToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh-token-string",
  "expiresIn": 3600  // seconds
}
```

### Token Refresh

**Endpoint**: `POST /auth/refresh`

```dart
final response = await dio.post(
  '${ApiConstants.baseUrl}/auth/refresh',
  data: {
    'refreshToken': refreshToken,
    'email': email,
  },
);

// Response
{
  "idToken": "new-id-token",
  "accessToken": "new-access-token",
  "expiresIn": 3600
}
```

### Authorization Header

**CRITICAL**: Use `idToken` (not `accessToken`) for API authorization:

```dart
headers: {
  'Authorization': 'Bearer ${session.idToken}'
}
```

### Token Storage

```dart
// Store tokens in encrypted Hive box
final box = await Hive.openBox<Map<String, dynamic>>(
  'sessions',
  encryptionCipher: HiveAesCipher(encryptionKey),
);

await box.put('current_session', {
  'idToken': idToken,
  'accessToken': accessToken,
  'refreshToken': refreshToken,
  'expiresAt': DateTime.now().add(Duration(seconds: expiresIn)),
  'userId': userId,
  'email': email,
});
```

### Auto-Refresh Logic

Implemented in `AuthInterceptor`:

```dart
// Check if token expires within 5 minutes
if (session.isExpiringSoon && !session.isExpired) {
  await _refreshToken();
}

// Reject request if token already expired
if (session.isExpired) {
  return handler.reject(DioException(...));
}
```

## GraphQL Integration

### Client Setup

```dart
final httpLink = HttpLink(
  ApiConstants.graphqlEndpoint,
  defaultHeaders: {
    'Authorization': 'Bearer ${session.idToken}',
  },
);

final authLink = AuthLink(
  getToken: () async {
    final session = await _authLocalDataSource.getSession();
    return 'Bearer ${session?.idToken}';
  },
);

final link = authLink.concat(httpLink);

final client = GraphQLClient(
  cache: GraphQLCache(),
  link: link,
);
```

### Queries

#### List Devices

```graphql
query ListDevices {
  listDevices {
    id
    name
    type
    status
    temperature
    isHeating
    targetTemperature
    lastSeen
  }
}
```

```dart
final result = await client.query(
  QueryOptions(
    document: gql(listDevicesQuery),
    fetchPolicy: FetchPolicy.networkOnly,
  ),
);

if (result.hasException) {
  throw result.exception!;
}

final devices = (result.data!['listDevices'] as List)
    .map((json) => Device.fromJson(json))
    .toList();
```

#### Get Device Details

```graphql
query GetDevice($id: ID!) {
  getDevice(id: $id) {
    id
    name
    type
    status
    temperature
    isHeating
    targetTemperature
    humidity
    powerLevel
    lastSeen
    firmwareVersion
  }
}
```

```dart
final result = await client.query(
  QueryOptions(
    document: gql(getDeviceQuery),
    variables: {'id': deviceId},
  ),
);
```

#### List Events

```graphql
query ListEvents(
  $startDate: DateTime!
  $endDate: DateTime!
  $limit: Int
  $nextToken: String
) {
  listEvents(
    startDate: $startDate
    endDate: $endDate
    limit: $limit
    nextToken: $nextToken
  ) {
    items {
      id
      deviceId
      eventType
      timestamp
      temperature
      isAcknowledged
      metadata
    }
    nextToken
  }
}
```

```dart
final result = await client.query(
  QueryOptions(
    document: gql(listEventsQuery),
    variables: {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'limit': 50,
      'nextToken': nextToken,
    },
  ),
);
```

### Mutations

#### Update Device Status

```graphql
mutation UpdateDeviceStatus($input: UpdateDeviceInput!) {
  updateDevice(input: $input) {
    id
    status
    isHeating
    temperature
    targetTemperature
    updatedAt
  }
}
```

```dart
final result = await client.mutate(
  MutationOptions(
    document: gql(updateDeviceMutation),
    variables: {
      'input': {
        'deviceId': deviceId,
        'status': 'ON',  // or 'OFF'
        'targetTemperature': 80,
      },
    },
  ),
);
```

#### Acknowledge Event

```graphql
mutation AcknowledgeEvent($input: AcknowledgeEventInput!) {
  acknowledgeEvent(input: $input) {
    id
    isAcknowledged
    acknowledgedAt
  }
}
```

```dart
final result = await client.mutate(
  MutationOptions(
    document: gql(acknowledgeEventMutation),
    variables: {
      'input': {
        'eventId': eventId,
      },
    },
  ),
);
```

## REST Integration

### Dio Client Setup

```dart
final dio = Dio(
  BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);

// Add interceptors
dio.interceptors.addAll([
  AuthInterceptor(
    localDataSource: authLocalDataSource,
    remoteDataSource: authRemoteDataSource,
  ),
  RateLimitInterceptor(
    config: RateLimitConfig.standard, // 60 req/min
  ),
  LoggingInterceptor(),
]);
```

### Error Handling

```dart
try {
  final response = await dio.post('/auth/token', data: credentials);
  return TokenResponse.fromJson(response.data);
} on DioException catch (e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      throw NetworkException('Connection timeout');
    case DioExceptionType.receiveTimeout:
      throw NetworkException('Receive timeout');
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      switch (statusCode) {
        case 401:
          throw AuthException('Invalid credentials');
        case 429:
          throw RateLimitException('Too many requests');
        default:
          throw ServerException('Server error: $statusCode');
      }
    default:
      throw NetworkException('Network error: ${e.message}');
  }
}
```

## WebSocket Subscriptions

### Setup

```dart
final wsLink = WebSocketLink(
  ApiConstants.websocketEndpoint,
  config: SocketClientConfig(
    autoReconnect: true,
    inactivityTimeout: const Duration(seconds: 30),
    initialPayload: () async {
      final session = await _authLocalDataSource.getSession();
      return {
        'Authorization': 'Bearer ${session?.idToken}',
      };
    },
  ),
);

final client = GraphQLClient(
  cache: GraphQLCache(),
  link: wsLink,
);
```

### Device State Subscription

```graphql
subscription OnDeviceStateChanged($deviceId: ID!) {
  onDeviceStateChanged(deviceId: $deviceId) {
    id
    status
    temperature
    isHeating
    targetTemperature
    timestamp
  }
}
```

```dart
final subscription = client.subscribe(
  SubscriptionOptions(
    document: gql(deviceStateSubscription),
    variables: {'deviceId': deviceId},
  ),
);

subscription.listen((result) {
  if (result.hasException) {
    AppLogger.e('Subscription error', error: result.exception);
    return;
  }
  
  final deviceState = DeviceState.fromJson(
    result.data!['onDeviceStateChanged'],
  );
  
  // Update local state
  _updateDeviceState(deviceState);
});
```

### Event Subscription

```graphql
subscription OnNewEvent {
  onNewEvent {
    id
    deviceId
    eventType
    timestamp
    temperature
    metadata
  }
}
```

```dart
final subscription = client.subscribe(
  SubscriptionOptions(
    document: gql(newEventSubscription),
  ),
);

subscription.listen((result) {
  final event = SaunaEvent.fromJson(result.data!['onNewEvent']);
  
  // Show notification
  _showEventNotification(event);
  
  // Update local storage
  _saveEventLocally(event);
});
```

## Error Handling

### Error Types

```dart
abstract class APIException implements Exception {
  final String message;
  const APIException(this.message);
}

class NetworkException extends APIException {
  const NetworkException(super.message);
}

class AuthException extends APIException {
  const AuthException(super.message);
}

class ServerException extends APIException {
  const ServerException(super.message);
}

class RateLimitException extends APIException {
  const RateLimitException(super.message);
}
```

### GraphQL Error Handling

```dart
if (result.hasException) {
  final exception = result.exception!;
  
  // Network errors
  if (exception.linkException != null) {
    throw NetworkException('Network error: ${exception.linkException}');
  }
  
  // GraphQL errors
  if (exception.graphqlErrors.isNotEmpty) {
    final error = exception.graphqlErrors.first;
    
    switch (error.extensions?['code']) {
      case 'UNAUTHENTICATED':
        throw AuthException('Authentication required');
      case 'FORBIDDEN':
        throw AuthException('Access denied');
      case 'NOT_FOUND':
        throw ServerException('Resource not found');
      default:
        throw ServerException(error.message);
    }
  }
}
```

## Rate Limiting

### Configuration

```dart
// Standard: 60 requests per minute
final interceptor = RateLimitInterceptor(
  config: RateLimitConfig.standard,
);

// Aggressive: 30 requests per minute
final interceptor = RateLimitInterceptor(
  config: RateLimitConfig.aggressive,
);

// Relaxed: 120 requests per minute
final interceptor = RateLimitInterceptor(
  config: RateLimitConfig.relaxed,
);

// Custom
final interceptor = RateLimitInterceptor(
  config: RateLimitConfig(
    maxRequests: 100,
    windowDuration: Duration(minutes: 1),
    enableBackoff: true,
  ),
);
```

### Handling 429 Errors

The rate limit interceptor automatically handles 429 errors with exponential backoff:

```
1st retry: wait 1 second
2nd retry: wait 2 seconds
3rd retry: wait 4 seconds
4th retry: wait 8 seconds
5th retry: wait 16 seconds
6th retry: wait 32 seconds (max)
```

## Best Practices

### 1. Offline-First Approach

Always save data locally first, then sync to API:

```dart
// Write operation
Future<void> updateDeviceStatus(String deviceId, String status) async {
  // 1. Update local storage immediately
  await _localDataSource.updateDevice(deviceId, status);
  
  try {
    // 2. Sync to API
    await _remoteDataSource.updateDevice(deviceId, status);
  } catch (e) {
    // 3. Queue for retry if network error
    if (e is NetworkException) {
      await _offlineSyncService.queueCommand(
        UpdateDeviceCommand(deviceId, status),
      );
    }
  }
}
```

### 2. Optimistic Updates

Update UI immediately, rollback on error:

```dart
Future<void> toggleDevice(String deviceId) async {
  // Get current state
  final device = await _localDataSource.getDevice(deviceId);
  final newStatus = device.status == 'ON' ? 'OFF' : 'ON';
  
  // Optimistic update
  await _localDataSource.updateDevice(deviceId, newStatus);
  state = AsyncData(device.copyWith(status: newStatus));
  
  try {
    // Sync to API
    await _remoteDataSource.updateDevice(deviceId, newStatus);
  } catch (e) {
    // Rollback on error
    await _localDataSource.updateDevice(deviceId, device.status);
    state = AsyncData(device);
    rethrow;
  }
}
```

### 3. Request Deduplication

Prevent duplicate requests:

```dart
final _pendingRequests = <String, Future<Device>>{};

Future<Device> getDevice(String deviceId) async {
  // Check for pending request
  if (_pendingRequests.containsKey(deviceId)) {
    return _pendingRequests[deviceId]!;
  }
  
  // Create new request
  final future = _fetchDevice(deviceId);
  _pendingRequests[deviceId] = future;
  
  try {
    return await future;
  } finally {
    _pendingRequests.remove(deviceId);
  }
}
```

### 4. Pagination

Use cursor-based pagination for event lists:

```dart
Future<PaginatedListState<SaunaEvent>> loadMoreEvents() async {
  final result = await _client.query(
    QueryOptions(
      document: gql(listEventsQuery),
      variables: {
        'limit': 50,
        'nextToken': state.nextToken,
      },
    ),
  );
  
  final data = result.data!['listEvents'];
  final newEvents = (data['items'] as List)
      .map((json) => SaunaEvent.fromJson(json))
      .toList();
  
  return state.copyWith(
    items: [...state.items, ...newEvents],
    nextToken: data['nextToken'],
    hasMore: data['nextToken'] != null,
  );
}
```

### 5. Error Recovery

Implement retry logic with exponential backoff:

```dart
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
}) async {
  int attempt = 0;
  
  while (true) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      
      if (attempt >= maxRetries || e is! NetworkException) {
        rethrow;
      }
      
      final delay = Duration(seconds: pow(2, attempt).toInt());
      AppLogger.w('Retry $attempt/$maxRetries after $delay');
      await Future.delayed(delay);
    }
  }
}
```

## Code Examples

### Complete Authentication Flow

```dart
class AuthRemoteDataSource {
  final Dio _dio;
  
  Future<TokenResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/token',
        data: {
          'username': email,
          'password': password,
        },
      );
      
      return TokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid credentials');
      }
      throw NetworkException('Login failed');
    }
  }
  
  Future<TokenResponse> refresh(String refreshToken, String email) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
        'email': email,
      },
    );
    
    return TokenResponse.fromJson(response.data);
  }
  
  Future<void> logout(String refreshToken, String email) async {
    await _dio.post(
      '/auth/revoke',
      data: {
        'refreshToken': refreshToken,
        'email': email,
      },
    );
  }
}
```

### Complete Device Control Flow

```dart
class DeviceRepository {
  final DeviceRemoteDataSource _remoteDataSource;
  final DeviceLocalDataSource _localDataSource;
  final OfflineSyncService _syncService;
  
  Future<void> updateDeviceStatus(
    String deviceId,
    String status,
  ) async {
    // Save locally first (offline-first)
    await _localDataSource.updateDeviceStatus(deviceId, status);
    
    try {
      // Sync to API
      await _remoteDataSource.updateDeviceStatus(deviceId, status);
    } catch (e) {
      if (e is NetworkException) {
        // Queue for later sync
        await _syncService.queueCommand(
          UpdateDeviceCommand(deviceId, status),
        );
      } else {
        rethrow;
      }
    }
  }
  
  Future<List<Device>> getDevices() async {
    // Read from local storage first
    final localDevices = await _localDataSource.getDevices();
    
    // Background sync from API
    _syncDevicesInBackground();
    
    return localDevices;
  }
  
  Future<void> _syncDevicesInBackground() async {
    try {
      final remoteDevices = await _remoteDataSource.getDevices();
      await _localDataSource.saveDevices(remoteDevices);
    } catch (e) {
      AppLogger.e('Background sync failed', error: e);
    }
  }
}
```

---

**Last Updated**: 2024-12-20  
**Version**: 1.0  
**For Questions**: Contact API team at api-support@harvia.com
