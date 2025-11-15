# API Contracts: Sauna Controller Mobile Application

**Feature**: Sauna Controller Mobile Application  
**Date**: 2025-11-15  
**API Base**: Harvia Cloud API  
**Documentation**: https://harvia.io/api

This document defines the external API contracts the mobile app will consume from the Harvia cloud services.

---

## API Overview

The Harvia API provides three main services accessed via different protocols:

1. **REST API** - Authentication and synchronous operations
2. **GraphQL HTTPS** - Query and mutation operations
3. **GraphQL WebSocket** - Real-time subscriptions

### Endpoint Configuration

All endpoints are dynamically retrieved from:
```
GET https://prod.api.harvia.io/endpoints
```

Response structure:
```json
{
  "endpoints": {
    "RestApi": {
      "generics": { "https": "<base-url>" },
      "device": { "https": "<base-url>" },
      "data": { "https": "<base-url>" }
    },
    "GraphQL": {
      "device": {
        "https": "<graphql-endpoint>",
        "wss": "<websocket-endpoint>"
      },
      "data": {
        "https": "<graphql-endpoint>",
        "wss": "<websocket-endpoint>"
      },
      "events": {
        "https": "<graphql-endpoint>",
        "wss": "<websocket-endpoint>"
      }
    }
  }
}
```

---

## 1. Authentication Service (REST API)

### POST /auth/token
**Purpose**: Authenticate user and obtain JWT tokens  
**Auth**: None (public endpoint)

**Request**:
```json
{
  "username": "user@example.com",
  "password": "secure-password"
}
```

**Response** (200 OK):
```json
{
  "idToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh-token-string",
  "expiresIn": 3600
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid credentials
- `400 Bad Request`: Malformed request

**App Usage**: Initial authentication on login screen

---

### POST /auth/refresh
**Purpose**: Refresh expired ID token using refresh token  
**Auth**: None (uses refresh token)

**Request**:
```json
{
  "refreshToken": "refresh-token-string",
  "email": "user@example.com"
}
```

**Response** (200 OK):
```json
{
  "idToken": "new-id-token",
  "accessToken": "new-access-token",
  "expiresIn": 3600
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or expired refresh token
- `400 Bad Request`: Missing parameters

**App Usage**: Automatic refresh before token expiry (every 55 minutes)

---

### POST /auth/revoke
**Purpose**: Revoke refresh token on logout  
**Auth**: None (uses refresh token)

**Request**:
```json
{
  "refreshToken": "refresh-token-string",
  "email": "user@example.com"
}
```

**Response** (200 OK):
```json
{
  "success": true
}
```

**App Usage**: User logout action

---

## 2. Device Service (GraphQL)

**Endpoint**: `endpoints.GraphQL.device.https`  
**WebSocket**: `endpoints.GraphQL.device.wss`  
**Auth**: `Authorization: Bearer <idToken>` header

### Query: listDevices
**Purpose**: Get all devices (controllers + sensors) for authenticated user

```graphql
query ListDevices {
  listDevices {
    devices {
      deviceId
      deviceType
      name
      model
      firmwareVersion
      connectionStatus
      lastSeen
      
      # Controller-specific fields
      powerState
      heatingStatus
      targetTemperature
      hasIntegratedSensor
      errorCode
      
      # Sensor-specific fields
      sensorType
      associatedControllerId
      batteryLevel
    }
  }
}
```

**Response**:
```json
{
  "data": {
    "listDevices": {
      "devices": [
        {
          "deviceId": "device-123",
          "deviceType": "CONTROLLER",
          "name": "Main Sauna",
          "model": "Xenio CX110",
          "firmwareVersion": "2.1.0",
          "connectionStatus": "ONLINE",
          "lastSeen": "2025-11-15T10:30:00Z",
          "powerState": "ON",
          "heatingStatus": "HEATING",
          "targetTemperature": 80.0,
          "hasIntegratedSensor": true,
          "errorCode": null
        },
        {
          "deviceId": "sensor-456",
          "deviceType": "SENSOR",
          "name": "External Temp Sensor",
          "sensorType": "TEMPERATURE",
          "associatedControllerId": "device-123",
          "batteryLevel": 85,
          "connectionStatus": "ONLINE",
          "lastSeen": "2025-11-15T10:29:00Z"
        }
      ]
    }
  }
}
```

**App Usage**: Fetch user's device list on app launch and after authentication

---

### Query: getDeviceState
**Purpose**: Get detailed current state of a specific device

```graphql
query GetDeviceState($deviceId: ID!) {
  getDeviceState(deviceId: $deviceId) {
    deviceId
    powerState
    heatingStatus
    currentTemperature
    targetTemperature
    humidity
    estimatedTimeToTarget
    errorCode
    errorMessage
    lastUpdated
  }
}
```

**Variables**:
```json
{
  "deviceId": "device-123"
}
```

**Response**:
```json
{
  "data": {
    "getDeviceState": {
      "deviceId": "device-123",
      "powerState": "ON",
      "heatingStatus": "HEATING",
      "currentTemperature": 65.5,
      "targetTemperature": 80.0,
      "humidity": 12.3,
      "estimatedTimeToTarget": 450,
      "errorCode": null,
      "errorMessage": null,
      "lastUpdated": "2025-11-15T10:30:00Z"
    }
  }
}
```

**App Usage**: Manual refresh, initial state fetch

---

### Mutation: sendDeviceCommand
**Purpose**: Send control command to device

```graphql
mutation SendCommand($input: DeviceCommandInput!) {
  sendDeviceCommand(input: $input) {
    success
    commandId
    message
    device {
      deviceId
      powerState
      targetTemperature
    }
  }
}
```

**Variables (Power On)**:
```json
{
  "input": {
    "deviceId": "device-123",
    "command": "POWER_ON",
    "parameters": {
      "targetTemperature": 80.0
    }
  }
}
```

**Variables (Power Off)**:
```json
{
  "input": {
    "deviceId": "device-123",
    "command": "POWER_OFF"
  }
}
```

**Variables (Set Temperature)**:
```json
{
  "input": {
    "deviceId": "device-123",
    "command": "SET_TEMPERATURE",
    "parameters": {
      "temperature": 85.0
    }
  }
}
```

**Response**:
```json
{
  "data": {
    "sendDeviceCommand": {
      "success": true,
      "commandId": "cmd-789",
      "message": "Command sent successfully",
      "device": {
        "deviceId": "device-123",
        "powerState": "ON",
        "targetTemperature": 85.0
      }
    }
  }
}
```

**Error Response**:
```json
{
  "errors": [
    {
      "message": "Device offline",
      "extensions": {
        "code": "DEVICE_OFFLINE"
      }
    }
  ]
}
```

**App Usage**: User control actions (power button, temperature slider)

---

### Subscription: onDeviceStateChange
**Purpose**: Real-time updates when device state changes

```graphql
subscription OnDeviceStateChange($deviceId: ID!) {
  onDeviceStateChange(deviceId: $deviceId) {
    deviceId
    powerState
    heatingStatus
    currentTemperature
    targetTemperature
    humidity
    errorCode
    errorMessage
    timestamp
  }
}
```

**Variables**:
```json
{
  "deviceId": "device-123"
}
```

**Stream Messages**:
```json
{
  "data": {
    "onDeviceStateChange": {
      "deviceId": "device-123",
      "powerState": "ON",
      "heatingStatus": "HEATING",
      "currentTemperature": 66.2,
      "targetTemperature": 80.0,
      "humidity": 12.5,
      "errorCode": null,
      "errorMessage": null,
      "timestamp": "2025-11-15T10:31:00Z"
    }
  }
}
```

**App Usage**: Dashboard real-time status updates (WebSocket subscription)

---

## 3. Data Service (GraphQL)

**Endpoint**: `endpoints.GraphQL.data.https`  
**WebSocket**: `endpoints.GraphQL.data.wss`  
**Auth**: `Authorization: Bearer <idToken>` header

### Query: getLatestData
**Purpose**: Get latest telemetry data from sensors

```graphql
query GetLatestData($deviceIds: [ID!]!) {
  getLatestData(deviceIds: $deviceIds) {
    readings {
      deviceId
      timestamp
      temperature
      humidity
      batteryLevel
    }
  }
}
```

**Variables**:
```json
{
  "deviceIds": ["sensor-456", "device-123"]
}
```

**Response**:
```json
{
  "data": {
    "getLatestData": {
      "readings": [
        {
          "deviceId": "sensor-456",
          "timestamp": "2025-11-15T10:30:00Z",
          "temperature": 65.8,
          "humidity": null,
          "batteryLevel": 85
        },
        {
          "deviceId": "device-123",
          "timestamp": "2025-11-15T10:30:00Z",
          "temperature": 65.5,
          "humidity": 12.3,
          "batteryLevel": null
        }
      ]
    }
  }
}
```

**App Usage**: Display sensor readings on dashboard

---

### Subscription: onSensorData
**Purpose**: Real-time sensor data updates

```graphql
subscription OnSensorData($deviceId: ID!) {
  onSensorData(deviceId: $deviceId) {
    deviceId
    timestamp
    temperature
    humidity
    batteryLevel
  }
}
```

**Variables**:
```json
{
  "deviceId": "sensor-456"
}
```

**Stream Messages**:
```json
{
  "data": {
    "onSensorData": {
      "deviceId": "sensor-456",
      "timestamp": "2025-11-15T10:31:00Z",
      "temperature": 65.9,
      "humidity": null,
      "batteryLevel": 85
    }
  }
}
```

**App Usage**: Real-time sensor reading updates

---

## 4. Events Service (GraphQL)

**Endpoint**: `endpoints.GraphQL.events.https`  
**WebSocket**: `endpoints.GraphQL.events.wss`  
**Auth**: `Authorization: Bearer <idToken>` header

### Query: listEvents
**Purpose**: Fetch event history with filtering

```graphql
query ListEvents($filter: EventFilterInput!, $limit: Int, $nextToken: String) {
  listEvents(filter: $filter, limit: $limit, nextToken: $nextToken) {
    events {
      eventId
      timestamp
      eventType
      severity
      deviceId
      title
      description
      metadata
    }
    nextToken
  }
}
```

**Variables**:
```json
{
  "filter": {
    "deviceIds": ["device-123"],
    "eventTypes": ["ERROR", "WARNING"],
    "severities": ["CRITICAL", "HIGH"],
    "startTime": "2025-11-01T00:00:00Z",
    "endTime": "2025-11-15T23:59:59Z"
  },
  "limit": 50
}
```

**Response**:
```json
{
  "data": {
    "listEvents": {
      "events": [
        {
          "eventId": "evt-123",
          "timestamp": "2025-11-15T08:45:00Z",
          "eventType": "ERROR",
          "severity": "HIGH",
          "deviceId": "device-123",
          "title": "Temperature sensor error",
          "description": "Temperature reading out of expected range",
          "metadata": {
            "sensorId": "sensor-456",
            "reading": 150.5
          }
        }
      ],
      "nextToken": "next-page-token"
    }
  }
}
```

**App Usage**: Event history screen with filters

---

### Subscription: onEvent
**Purpose**: Real-time event notifications

```graphql
subscription OnEvent($deviceIds: [ID!]) {
  onEvent(deviceIds: $deviceIds) {
    eventId
    timestamp
    eventType
    severity
    deviceId
    title
    description
    metadata
  }
}
```

**Variables**:
```json
{
  "deviceIds": ["device-123", "sensor-456"]
}
```

**Stream Messages**:
```json
{
  "data": {
    "onEvent": {
      "eventId": "evt-124",
      "timestamp": "2025-11-15T10:32:00Z",
      "eventType": "WARNING",
      "severity": "MEDIUM",
      "deviceId": "device-123",
      "title": "Target temperature reached",
      "description": "Sauna has reached target temperature of 80°C",
      "metadata": {
        "currentTemp": 80.0,
        "targetTemp": 80.0
      }
    }
  }
}
```

**App Usage**: Real-time event notifications, push notification triggers

---

## Error Handling

### Common GraphQL Error Codes

| Code | Meaning | App Action |
|------|---------|------------|
| `UNAUTHENTICATED` | Invalid/expired token | Refresh token or re-login |
| `DEVICE_OFFLINE` | Device not reachable | Show offline status, queue command |
| `INVALID_COMMAND` | Unsupported command for device | Show error message |
| `RATE_LIMIT_EXCEEDED` | Too many requests | Exponential backoff retry |
| `INTERNAL_ERROR` | Server error | Retry with backoff, show error |
| `INVALID_PARAMETER` | Bad parameter value | Show validation error to user |

### HTTP Status Codes (REST)

| Status | Meaning | App Action |
|--------|---------|------------|
| `200` | Success | Process response |
| `400` | Bad request | Show validation error |
| `401` | Unauthorized | Refresh or re-login |
| `429` | Rate limited | Exponential backoff |
| `500` | Server error | Retry, show error |
| `503` | Service unavailable | Queue action, retry later |

---

## Rate Limiting

**Limits** (Estimated - verify in production):
- REST API: 100 requests/minute per user
- GraphQL Queries: 200 requests/minute per user
- GraphQL Mutations: 50 requests/minute per user
- WebSocket Subscriptions: 10 concurrent connections per user

**App Strategies**:
- Use subscriptions instead of polling
- Debounce user input (temperature slider)
- Cache query results
- Batch mutations when possible

---

## Data Types Reference

```graphql
# Common scalar types
scalar DateTime    # ISO 8601 format: "2025-11-15T10:30:00Z"
scalar ID          # Unique identifier string

# Enums
enum PowerState {
  ON
  OFF
  UNKNOWN
}

enum HeatingStatus {
  HEATING
  IDLE
  COOLING
  ERROR
  UNKNOWN
}

enum ConnectionStatus {
  ONLINE
  OFFLINE
  UNKNOWN
}

enum DeviceType {
  CONTROLLER
  SENSOR
}

enum SensorType {
  TEMPERATURE
  HUMIDITY
  COMBINED
}

enum EventType {
  ERROR
  WARNING
  INFO
  STATE_CHANGE
  MAINTENANCE
  SAFETY
}

enum EventSeverity {
  CRITICAL
  HIGH
  MEDIUM
  LOW
}

enum CommandType {
  POWER_ON
  POWER_OFF
  SET_TEMPERATURE
  SET_PROFILE
}
```

---

## Testing Contracts

### Mock Responses

For integration tests, create mock responses following these contracts:
- Store in `test/fixtures/api/` as JSON files
- Use `mockito` to intercept HTTP/GraphQL calls
- Verify request structure matches contract
- Simulate error scenarios

### Contract Validation

Before deploying:
1. Verify all queries/mutations against live API schema
2. Test subscription reconnection scenarios
3. Validate error code handling
4. Check rate limiting behavior

---

**Phase 1 Complete**: API contracts defined for all external service integrations. Ready to generate quickstart documentation.
