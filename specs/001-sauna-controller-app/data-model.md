# Phase 1: Data Model & Entities

**Feature**: Sauna Controller Mobile Application  
**Date**: 2025-11-15  
**Status**: Complete

This document defines the core data entities, their attributes, relationships, and validation rules based on the feature specification and research findings.

---

## Entity Relationship Overview

```
User Account (Cloud)
    ↓ owns
    ├─→ Sauna Controller (Cloud Device)
    │       ↓ has/controls
    │       └─→ Sensor Device (optional, Cloud Device)
    │
    ├─→ API Session (Local State)
    │
    ├─→ Heating Schedule (Local Storage)
    │
    ├─→ Event (Local Cache + Real-time Stream)
    │
    └─→ Command Request (Transient State)
```

---

## 1. User Account

**Source**: Cloud API (Harvia Cognito)  
**Storage**: Secure credentials in flutter_secure_storage, user profile in memory

### Attributes

| Attribute | Type | Required | Validation | Notes |
|-----------|------|----------|------------|-------|
| `email` | String | Yes | Valid email format | Used as username for authentication |
| `userId` | String | Yes | Non-empty | Cognito user ID |
| `displayName` | String | No | Max 100 chars | User's display name if available |
| `linkedDevices` | List<String> | Yes | Device IDs | Controllers and sensors owned by user |
| `preferences` | UserPreferences | No | - | App settings (units, notifications) |

### Relationships
- Has many: `SaunaController`, `SensorDevice`
- Has one: `APISession`

### State Transitions
1. Unauthenticated → Authenticating (login attempt)
2. Authenticating → Authenticated (tokens received)
3. Authenticating → Unauthenticated (login failed)
4. Authenticated → Unauthenticated (logout)

---

## 2. Sauna Controller

**Source**: Cloud API (Device Service)  
**Storage**: Cached in Hive, live state in Riverpod

### Attributes

| Attribute | Type | Required | Validation | Notes |
|-----------|------|----------|------------|-------|
| `deviceId` | String | Yes | Non-empty, unique | Primary identifier |
| `model` | String | Yes | Non-empty | e.g., "Harvia Xenio CX110" |
| `name` | String | No | Max 50 chars | User-assigned friendly name |
| `firmwareVersion` | String | No | Semver format | Current firmware version |
| `targetTemperature` | double | No | 40-100°C or model range | Desired temperature |
| `powerState` | PowerState | Yes | on/off/unknown | Current power status |
| `heatingStatus` | HeatingStatus | Yes | enum | heating/idle/cooling/error |
| `connectionStatus` | ConnectionStatus | Yes | enum | online/offline/unknown |
| `errorState` | String? | No | - | Current error code if any |
| `lastSeen` | DateTime | No | - | Last communication timestamp |
| `hasIntegratedSensor` | bool | Yes | - | True if controller has built-in sensor |
| `associatedSensorIds` | List<String> | No | Valid sensor IDs | Linked standalone sensors |

### Enums

```dart
enum PowerState { on, off, unknown }
enum HeatingStatus { heating, idle, cooling, error, unknown }
enum ConnectionStatus { online, offline, unknown }
```

### Relationships
- Belongs to: `UserAccount`
- Has many (optional): `SensorDevice` (standalone sensors)
- Has many: `Event` (operational events)
- Has many: `CommandRequest` (control history)

### Validation Rules
- `targetTemperature` must be within safe operating range for model
- Cannot set target temperature when `powerState` is `off`
- `errorState` present only when `heatingStatus` is `error`

### State Transitions
```
Power: off → on (user command) → heating (controller response)
Heating: idle → heating (target temp set) → idle (target reached)
Connection: online ↔ offline (network/device status)
```

---

## 3. Sensor Device

**Source**: Cloud API (Device Service + Data Service)  
**Storage**: Cached in Hive, live readings in Riverpod

### Attributes

| Attribute | Type | Required | Validation | Notes |
|-----------|------|----------|------------|-------|
| `sensorId` | String | Yes | Non-empty, unique | Primary identifier |
| `sensorType` | SensorType | Yes | enum | temperature/humidity/combined |
| `name` | String | No | Max 50 chars | User-assigned friendly name |
| `currentTemperature` | double? | No | -20 to 150°C | Latest temperature reading |
| `currentHumidity` | double? | No | 0-100% | Latest humidity reading |
| `batteryLevel` | int? | No | 0-100 | Battery percentage if battery-powered |
| `lastUpdate` | DateTime | Yes | - | Timestamp of last reading |
| `associatedControllerId` | String? | No | Valid device ID | Linked controller if any |
| `firmwareVersion` | String | No | Semver format | Sensor firmware version |

### Enums

```dart
enum SensorType {
  temperature,     // Temperature only
  humidity,        // Humidity only
  combined         // Both temperature and humidity
}
```

### Relationships
- Belongs to: `UserAccount`
- Belongs to (optional): `SaunaController` (if associated)

### Validation Rules
- `currentTemperature` and `currentHumidity` immutable (read-only)
- At least one reading (`currentTemperature` or `currentHumidity`) must be present
- `sensorType` determines which readings are available
- Humidity is display-only, no control capability (per FR-023)

### State Transitions
```
Unlinked → Linked (manual association to controller)
Linked → Unlinked (user removes association)
Reading update: lastUpdate timestamp changes on new data
```

---

## 4. Heating Schedule

**Source**: Local storage only (not synced to cloud per clarifications)  
**Storage**: Hive box with type adapter

### Attributes

| Attribute | Type | Required | Validation | Notes |
|-----------|------|----------|------------|-------|
| `scheduleId` | String | Yes | UUID | Local unique identifier |
| `deviceId` | String | Yes | Valid controller ID | Target sauna controller |
| `scheduledTime` | TimeOfDay | Yes | Valid 24h time | When to activate |
| `targetTemperature` | double | Yes | Device safe range | Temperature to set |
| `daysOfWeek` | List<int> | Yes | 1-7 (Mon-Sun) | Which days schedule runs |
| `enabled` | bool | Yes | - | Active/paused status |
| `lastExecution` | DateTime? | No | - | Last successful run |
| `createdAt` | DateTime | Yes | - | Schedule creation time |
| `notifyBefore` | Duration | No | 5-60 minutes | Reminder notification lead time |

### Relationships
- Belongs to: `SaunaController` (via deviceId)

### Validation Rules
- `scheduledTime` must be in the future for next execution
- `targetTemperature` must be within controller's safe operating range
- `daysOfWeek` must contain at least one day (1-7)
- Cannot have multiple enabled schedules for same device at exact same time
- `notifyBefore` defaults to 15 minutes if not specified

### State Transitions
```
Created → Enabled (user creates schedule)
Enabled → Disabled (user toggles off)
Enabled → Executing (scheduled time arrives, app running)
Executing → Enabled (command sent successfully)
```

### Business Rules
- Schedules execute only when app is running (foreground or background)
- Notification reminder sent when `scheduledTime - notifyBefore` arrives
- If app not running at scheduled time, next execution is next matching day
- Failed executions retry once after 1 minute if still within schedule window

---

## 5. Event

**Source**: Cloud API (Events Service) + Local generation  
**Storage**: Hive box (ring buffer, max 1000 events)

### Attributes

| Attribute | Type | Required | Validation | Notes |
|-----------|------|----------|------------|-------|
| `eventId` | String | Yes | Non-empty, unique | Event identifier |
| `timestamp` | DateTime | Yes | - | When event occurred |
| `eventType` | EventType | Yes | enum | Category of event |
| `severity` | EventSeverity | Yes | enum | Importance level |
| `deviceId` | String | Yes | Valid device ID | Related controller/sensor |
| `title` | String | Yes | Max 100 chars | Short event description |
| `description` | String | No | Max 500 chars | Detailed event message |
| `acknowledged` | bool | Yes | - | User has viewed/dismissed |
| `metadata` | Map<String, dynamic> | No | Valid JSON | Additional event data |

### Enums

```dart
enum EventType {
  error,           // System errors, failures
  warning,         // Warnings requiring attention
  info,            // Informational events
  stateChange,     // Power on/off, mode changes
  maintenance,     // Maintenance alerts
  safety           // Safety-critical alerts
}

enum EventSeverity {
  critical,        // Immediate action required
  high,            // Important but not immediate
  medium,          // Notable but routine
  low              // Informational only
}
```

### Relationships
- Belongs to: `SaunaController` or `SensorDevice` (via deviceId)

### Validation Rules
- Events are immutable once created (read-only)
- `severity = critical` triggers immediate push notification
- `eventType = safety` always has `severity = critical`
- Events auto-deleted after 30 days or when count exceeds 1000 (oldest first)

### Display Filters
- Filter by: `eventType`, `severity`, `deviceId`, date range
- Sort by: `timestamp` (newest first default)
- Group by: Device, severity, or date

---

## 6. API Session

**Source**: REST API authentication endpoint  
**Storage**: Secure storage (tokens) + memory (session state)

### Attributes

| Attribute | Type | Required | Validation | Notes |
|-----------|------|----------|------------|-------|
| `idToken` | String | Yes | Valid JWT | API authorization token |
| `accessToken` | String | Yes | Valid JWT | AWS Cognito access token |
| `refreshToken` | String | Yes | Non-empty | Long-lived refresh token |
| `tokenExpiry` | DateTime | Yes | Future timestamp | When idToken expires (1 hour) |
| `userEmail` | String | Yes | Valid email | For token refresh calls |
| `sessionState` | SessionState | Yes | enum | Connection status |
| `lastRefresh` | DateTime | Yes | - | Last token refresh time |

### Enums

```dart
enum SessionState {
  authenticated,    // Valid active session
  refreshing,       // Refreshing expired token
  unauthenticated,  // No valid session
  expired           // Session expired, refresh failed
}
```

### Relationships
- Belongs to: `UserAccount`

### Validation Rules
- `idToken` must be refreshed before `tokenExpiry`
- Auto-refresh triggered at `tokenExpiry - 5 minutes`
- Maximum 3 refresh retry attempts before requiring re-login
- `refreshToken` stored encrypted in secure storage

### State Transitions
```
unauthenticated → authenticated (successful login)
authenticated → refreshing (token near expiry)
refreshing → authenticated (refresh success)
refreshing → expired (refresh failed)
expired → unauthenticated (logout)
```

---

## 7. Command Request

**Source**: User interaction + local scheduling  
**Storage**: Transient (in-memory queue), failed commands cached for retry

### Attributes

| Attribute | Type | Required | Validation | Notes |
|-----------|------|----------|------------|-------|
| `requestId` | String | Yes | UUID | Unique request identifier |
| `deviceId` | String | Yes | Valid controller ID | Target device |
| `commandType` | CommandType | Yes | enum | Type of command |
| `parameters` | Map<String, dynamic> | No | Type-specific | Command parameters |
| `timestamp` | DateTime | Yes | - | When command was created |
| `status` | CommandStatus | Yes | enum | Current execution status |
| `errorMessage` | String? | No | - | Error details if failed |
| `retryCount` | int | Yes | 0-3 | Number of retry attempts |

### Enums

```dart
enum CommandType {
  powerOn,          // Turn sauna on
  powerOff,         // Turn sauna off
  setTemperature,   // Adjust target temperature
  setProfile        // Change device profile (if supported)
}

enum CommandStatus {
  pending,          // Queued for execution
  executing,        // Being sent to API
  succeeded,        // Confirmed successful
  failed,           // Execution failed
  retrying          // Retrying after failure
}
```

### Parameters by Command Type

| CommandType | Parameters | Validation |
|-------------|------------|------------|
| powerOn | `{ targetTemp?: double }` | Optional temp in safe range |
| powerOff | None | - |
| setTemperature | `{ temperature: double }` | Required, in safe range |
| setProfile | `{ profileId: string }` | Valid profile ID |

### Relationships
- Belongs to: `SaunaController` (via deviceId)
- Created by: User action or `HeatingSchedule` execution

### Validation Rules
- Commands queued when offline, executed when online
- Failed commands retry with exponential backoff (1s, 2s, 4s)
- Maximum 3 retry attempts before marking as failed
- Cannot send `setTemperature` when controller `powerState = off`
- Commands expire after 5 minutes in queue

### State Transitions
```
created → pending (added to queue)
pending → executing (network available, sending)
executing → succeeded (API confirmation received)
executing → failed (error response)
executing → retrying (temporary failure, retry scheduled)
retrying → executing (retry attempt)
failed → pending (user manual retry)
```

---

## Data Flow Diagrams

### Authentication Flow
```
User Input (email/password)
  → REST API /auth/token
  → APISession created (tokens stored securely)
  → Fetch user devices via GraphQL
  → Cache devices in Hive
  → Subscribe to device updates (WebSocket)
```

### Real-Time Status Update Flow
```
GraphQL Subscription (device state)
  → WebSocket message received
  → Parse device state update
  → Update Riverpod state provider
  → UI auto-updates via consumer
  → Cache latest state in Hive
```

### Control Command Flow
```
User Action (button tap)
  → Create CommandRequest
  → Validate command (power state, temp range)
  → Add to execution queue
  → Send GraphQL mutation
  → Await confirmation
  → Update CommandRequest status
  → Update UI with result
```

### Schedule Execution Flow
```
Background Task checks schedules (every 15 min)
  → Find schedules within next 15 min
  → Send notification reminder
  → On notification tap OR scheduled time:
    → Open app
    → Create CommandRequest (powerOn + setTemp)
    → Execute command via normal flow
    → Update schedule.lastExecution
```

### Event Notification Flow
```
GraphQL Subscription (events)
  → Event received
  → Parse and create Event entity
  → Store in Hive event box
  → Check severity level
  → If critical: trigger local push notification
  → Update event list UI
  → Apply user notification filters
```

---

## Storage Strategy Summary

| Entity | Primary Storage | Cache | Sync Strategy |
|--------|----------------|-------|---------------|
| UserAccount | Cloud (Cognito) | Secure storage | On login/refresh |
| SaunaController | Cloud (Device Service) | Hive | Real-time subscription |
| SensorDevice | Cloud (Data Service) | Hive | Real-time subscription |
| HeatingSchedule | Hive (local only) | N/A | Local only |
| APISession | Secure storage | Memory | On login/refresh |
| Event | Cloud (Events Service) | Hive (ring buffer) | Real-time subscription |
| CommandRequest | Memory (queue) | Hive (failures) | Ephemeral + retry |

---

## Model Implementation Notes

### Code Generation Requirements
- Hive type adapters for `HeatingSchedule`, `Event`
- Freezed/json_serializable for all models for immutability and JSON serialization
- Riverpod code generation for providers

### Null Safety
- All DateTime fields non-nullable with UTC timezone
- Optional readings (humidity, battery) properly typed as nullable
- Use Dart 3 pattern matching for state transitions

### Testing Strategy
- Unit tests for model validation rules
- Test state transition logic
- Mock API responses for entity deserialization
- Test Hive storage/retrieval for local entities

---

**Phase 1 Complete**: Data model defined with all attributes, relationships, validation rules, and state transitions. Ready to proceed to API contract generation.
