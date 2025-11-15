# Dynamic URL Configuration

## Overview

The Harvia API uses **three different REST API base URLs** for different service types:

1. **Generics** (`/auth/*`): Authentication and generic operations
2. **Device** (`/devices/*`): Device configuration and management  
3. **Data** (`/data/*`): Latest sensor data and events

This implementation now uses dynamic endpoint discovery with proper URL type mapping.

## Service Discovery

### Endpoint: `GET https://prod.api.harvia.io/endpoints`

Returns:
```json
{
  "endpoints": {
    "RestApi": {
      "generics": { "https": "https://zft3sdx910.execute-api.eu-central-1.amazonaws.com/prod" },
      "device": { "https": "https://ap754v98f8.execute-api.eu-central-1.amazonaws.com/prod" },
      "data": { "https": "https://u4830dkpl0.execute-api.eu-central-1.amazonaws.com/prod" }
    },
    "GraphQL": {
      "device": {
        "https": "https://6lhlukqhbzefnhad2qdyg2lffm.appsync-api.eu-central-1.amazonaws.com/graphql",
        "wss": "wss://6lhlukqhbzefnhad2qdyg2lffm.appsync-realtime-api.eu-central-1.amazonaws.com/graphql"
      },
      "data": {
        "https": "https://b6ypjrrojzfuleunmrsysp7aya.appsync-api.eu-central-1.amazonaws.com/graphql",
        "wss": "wss://b6ypjrrojzfuleunmrsysp7aya.appsync-realtime-api.eu-central-1.amazonaws.com/graphql"
      },
      "events": {
        "https": "https://ykn3dsmrrvc47lnzh5vowxevb4.appsync-api.eu-central-1.amazonaws.com/graphql",
        "wss": "wss://ykn3dsmrrvc47lnzh5vowxevb4.appsync-realtime-api.eu-central-1.amazonaws.com/graphql"
      }
    }
  }
}
```

## URL Type Mapping

### REST API Service Types

#### 1. RestApiService.generics
**Base URL**: `endpoints.RestApi.generics.https`  
**Used for**:
- `POST /auth/token` - Login
- `POST /auth/refresh` - Refresh token
- `POST /auth/revoke` - Logout

**Files**:
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`

#### 2. RestApiService.device
**Base URL**: `endpoints.RestApi.device.https`  
**Used for**:
- `GET /devices` - List devices
- `GET /devices/{id}` - Get device details
- `PUT /devices/{id}` - Update device configuration

**Files**:
- To be created when REST device endpoints are needed

#### 3. RestApiService.data
**Base URL**: `endpoints.RestApi.data.https`  
**Used for**:
- `GET /data/latest-data?deviceId={id}` - Get latest device state
- `GET /data/events` - Get event history

**Files**:
- To be created when REST data endpoints are needed

### GraphQL Endpoints

Currently using hardcoded GraphQL URLs for:
- **Device operations**: Queries, mutations, subscriptions for device management
- **Data operations**: Sensor data queries and subscriptions
- **Events operations**: Event history and notifications

## Implementation

### REST Client Configuration

```dart
// Authentication uses generics service
final authDio = RestApiClient.getDio(RestApiService.generics);
final response = await authDio.post('/auth/token', data: credentials);

// Device management uses device service
final deviceDio = RestApiClient.getDio(RestApiService.device);
final devices = await deviceDio.get('/devices');

// Latest data uses data service
final dataDio = RestApiClient.getDio(RestApiService.data);
final state = await dataDio.get('/data/latest-data', queryParameters: {'deviceId': id});
```

### Endpoint Configuration Classes

**Files created**:
1. `lib/core/config/endpoint_config.dart` - Data models for endpoint configuration
2. `lib/services/api/service_discovery_client.dart` - Fetches endpoints from discovery URL
3. `lib/core/config/endpoint_repository.dart` - Caches endpoints in Hive
4. `lib/services/api/endpoint_provider.dart` - Riverpod providers for dynamic URLs

### Fallback Strategy

If service discovery fails:
1. Use cached endpoints (valid for 24 hours)
2. Fall back to hardcoded endpoints from `ApiConstants`
3. Log warning and continue operation

## Current Status

✅ **Implemented**:
- Endpoint configuration models
- Service discovery client
- Endpoint caching repository
- Multiple REST API client support with service types
- Auth datasource using correct `generics` service

⏳ **Not Yet Implemented** (post-MVP):
- Riverpod providers (need code generation)
- Dynamic endpoint refresh on startup
- GraphQL client dynamic URL configuration
- Full integration testing

## Testing

### Manual Test with Python Script

The reference Python script (`api_test/devices.py`) demonstrates correct usage:

```python
# 1. Fetch endpoints
config = get_api_configuration()

# 2. Use generics for auth
rest_api_base_url = config["RestApi"]["generics"]["https"]
response = httpx.post(f"{rest_api_base_url}/auth/token", ...)

# 3. Use device for device list
device_base_url = config["RestApi"]["device"]["https"]
devices = httpx.get(f"{device_base_url}/devices", ...)

# 4. Use data for device state
data_base_url = config["RestApi"]["data"]["https"]
state = httpx.get(f"{data_base_url}/data/latest-data?deviceId={id}", ...)
```

### Verification Steps

1. ✅ Auth endpoints use `RestApiService.generics`
2. ⏳ Device endpoints use `RestApiService.device` (when implemented)
3. ⏳ Data endpoints use `RestApiService.data` (when implemented)
4. ✅ Each service has its own Dio instance with correct base URL
5. ✅ Fallback to hardcoded endpoints if discovery fails

## Next Steps

1. Run code generation for Riverpod providers: `flutter pub run build_runner build`
2. Initialize endpoint provider in main.dart
3. Update GraphQL client to use dynamic URLs
4. Add integration tests for endpoint discovery
5. Monitor endpoint changes in production

## Architecture Benefits

1. **Automatic Updates**: App adapts to endpoint changes without code updates
2. **Type Safety**: Enum prevents using wrong base URL for endpoints
3. **Performance**: Each service has dedicated Dio instance with connection pooling
4. **Resilience**: Fallback to cached/hardcoded endpoints on failure
5. **Debugging**: Clear logging shows which service and URL is being used

---

**Last Updated**: 2024-12-20  
**Status**: Implementation complete, code generation pending  
**Related Files**: See implementation section above
