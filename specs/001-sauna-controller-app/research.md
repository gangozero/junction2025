# Phase 0: Research & Technology Decisions

**Feature**: Sauna Controller Mobile Application  
**Date**: 2025-11-15  
**Status**: Complete

## Research Tasks Completed

All technical unknowns from the specification have been researched and resolved. This document captures the decisions made for implementing the Flutter mobile application.

---

## 1. State Management Selection

**Decision**: Use **Riverpod** for state management

**Rationale**:
- Compile-time safety with provider code generation
- Excellent support for async data fetching and caching
- Built-in testing utilities without mocking
- Strong community support and active maintenance
- Works well with GraphQL subscriptions and real-time data streams
- Supports both simple local state and complex app-wide state

**Alternatives Considered**:
- **Bloc**: More boilerplate, overkill for this app's complexity
- **Provider**: Less type-safe, more manual disposal management
- **GetX**: Controversial patterns, service locator anti-pattern concerns

**Implementation Notes**:
- Use `StateNotifierProvider` for device state, schedule management
- Use `StreamProvider` for GraphQL subscription data
- Use `FutureProvider` for one-time API calls
- Leverage `family` and `autoDispose` modifiers for parameter-based providers

---

## 2. Local Database Selection

**Decision**: Use **Hive** for local data storage

**Rationale**:
- Pure Dart implementation (no native dependencies)
- Excellent performance for small-to-medium datasets
- Type-safe with code generation
- Minimal boilerplate compared to sqflite
- Perfect fit for storing schedules (structured) and events (append-only)
- Synchronous and asynchronous API support
- Built-in encryption support

**Alternatives Considered**:
- **sqflite**: More complex SQL setup, overkill for simple key-value and list storage
- **Drift (formerly Moor)**: Powerful but heavyweight, unnecessary complexity
- **Shared Preferences**: Too limited for structured data like event history

**Implementation Notes**:
- Create type adapters for `HeatingSchedule`, `Event`, `SensorData` models
- Use separate boxes for schedules, events, and cached device states
- Implement automatic cleanup for events older than 30 days
- Encrypt box containing authentication tokens

---

## 3. GraphQL Client Configuration

**Decision**: Use **graphql_flutter** package with custom WebSocket configuration

**Rationale**:
- Official GraphQL client for Flutter with strong community
- Built-in WebSocket support for subscriptions
- Integrates with flutter state management
- Automatic query caching and refetching
- Support for optimistic updates

**API Integration Strategy**:
- REST API for authentication (`/auth/token`, `/auth/refresh`, `/auth/revoke`)
- GraphQL queries for device list, device state, sensor data
- GraphQL mutations for device commands (power, temperature)
- GraphQL subscriptions for real-time status updates and events
- WebSocket auto-reconnection with exponential backoff

**Configuration Details**:
```dart
// Endpoint fetching from https://prod.api.harvia.io/endpoints
- REST base URL: Dynamic from config API
- GraphQL HTTPS: endpoints.GraphQL.device.https
- GraphQL WSS: endpoints.GraphQL.device.wss
- Events WSS: endpoints.GraphQL.events.wss
- Data HTTPS: endpoints.GraphQL.data.https
```

**Headers Required**:
- `Authorization: Bearer <idToken>` for all authenticated requests
- `Content-Type: application/json` for REST calls

---

## 4. Background Task Scheduling

**Decision**: Use **workmanager** for iOS/Android background tasks

**Rationale**:
- Cross-platform support for both iOS and Android
- Handles platform-specific limitations (iOS background refresh, Android Doze mode)
- Reliable scheduling even when app is terminated
- Can wake app to execute scheduled tasks

**Scheduling Strategy**:
- Use `registerPeriodicTask` to check for upcoming schedules every 15 minutes
- When schedule within next 15 minutes detected, send local notification reminder
- On notification tap, open app to execute schedule
- Use `registerOneOffTask` for immediate schedule execution when app in background

**Limitations to Communicate**:
- iOS: Background tasks may be delayed by system (not guaranteed exact timing)
- Android: Doze mode may delay tasks on some devices
- Best-effort delivery: SC-006 specifies "within 1 minute when app is running"

---

## 5. Push Notifications Implementation

**Decision**: Use **flutter_local_notifications** for local notifications

**Rationale**:
- No cloud messaging service needed (local scheduling, not remote push)
- Full control over notification content and timing
- Works offline
- Platform-specific customization (iOS sound, Android channels)

**Notification Categories**:
1. **Schedule Reminders**: Alert before scheduled activation time
2. **Critical Events**: Safety alerts, errors from Events Service
3. **Command Confirmations**: Optional success/failure feedback

**Platform Setup**:
- iOS: Request notification permissions on first launch
- Android: Create notification channels (Critical, Reminders, Info)

---

## 6. Secure Credential Storage

**Decision**: Use **flutter_secure_storage** for authentication tokens

**Rationale**:
- Platform-specific secure storage (iOS Keychain, Android KeyStore)
- Automatic encryption
- Simple key-value API
- Meets mobile security standards

**Stored Data**:
- `idToken`: JWT token for API authentication (1 hour expiry)
- `refreshToken`: Long-lived token for refreshing access
- `userEmail`: Username for token refresh calls
- `tokenExpiry`: Timestamp for automatic refresh logic

**Security Measures**:
- Tokens encrypted at rest
- Automatic token refresh before expiry
- Clear tokens on logout
- Validate tokens on app resume

---

## 7. Offline Support Strategy

**Decision**: Cache-first with background sync

**Approach**:
- **Read Path**: Always show cached data immediately, fetch updates in background
- **Write Path**: Queue commands, retry on connectivity restore
- **Sync Strategy**: GraphQL cache for device states, Hive for schedules/events

**Cached Data**:
- Last known device states (temperature, power, status)
- All heating schedules (local storage only)
- Recent 1000 events
- Device/sensor list

**Offline UX**:
- Clear "Offline" banner when no connectivity
- Show last updated timestamp on cached data
- Disable control commands when offline
- Queue schedule changes, sync when online

---

## 8. Real-Time Subscription Management

**Decision**: WebSocket connection pooling with automatic reconnection

**Strategy**:
- Single WebSocket connection per service (Device, Events, Data)
- Subscribe to all active devices on connection
- Exponential backoff on connection failure (1s, 2s, 4s, 8s, max 30s)
- Resubscribe on reconnection
- Heartbeat ping every 30 seconds to detect stale connections

**Subscription Lifecycle**:
```dart
App Foreground → Connect WebSocket → Subscribe to devices/events
App Background (< 5min) → Keep connection alive
App Background (> 5min) → Close connection, reconnect on foreground
Connection Lost → Auto-reconnect with backoff
Network Restored → Immediate reconnect attempt
```

---

## 9. Temperature Validation

**Decision**: Model-specific temperature ranges from API, with fallback defaults

**Approach**:
- Fetch safe operating ranges from device metadata on first connection
- Cache ranges locally per device model
- Fallback to conservative defaults if API doesn't provide ranges:
  - Traditional sauna: 40°C - 100°C (104°F - 212°F)
  - Steam room: 35°C - 50°C (95°F - 122°F)

**Validation Rules**:
- Block temperatures outside safe range (FR-011)
- Show warning at extreme ends (e.g., >90°C)
- Different ranges for different controller models
- Respect unit preference (Celsius/Fahrenheit)

---

## 10. API Rate Limiting Handling

**Decision**: Exponential backoff with user feedback

**Strategy**:
- Detect rate limit errors (HTTP 429)
- Implement exponential backoff (1s, 2s, 4s, 8s)
- Show user-friendly message: "Service temporarily busy, retrying..."
- Cache read requests to minimize API calls
- Batch multiple commands when possible

**Preventive Measures**:
- Debounce temperature slider updates (wait for user to stop adjusting)
- Throttle manual refresh requests (max once per 5 seconds)
- Use GraphQL subscriptions instead of polling

---

## 11. Multi-Device Support

**Decision**: Device selection with persistent preference

**UX Flow**:
1. After authentication, show device list if multiple devices
2. User selects primary device
3. Store selection in shared preferences
4. Show device switcher in app bar/settings
5. Support quick switch between devices (<5 seconds per SC-010)

**State Management**:
- Track "active device" in Riverpod provider
- Subscribe to updates only for active device
- Background sync schedules/events for all devices
- Show notification badge on inactive devices with critical events

---

## 12. Sensor-Controller Association

**Decision**: Automatic association by device ID with manual override

**Implementation**:
- API provides `associatedControllerId` field in sensor metadata
- Automatic: Display sensor data inline with controller if associated
- Manual linking: Settings screen to link/unlink sensors
- Store manual associations locally, sync preference to API if supported

**Display Strategy**:
- Integrated sensors: Show as part of controller card
- Standalone sensors: Separate expandable section showing all readings
- Orphaned sensors: "Unlinked Sensors" section with link button

---

## Technology Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| Framework | Flutter | 3.16+ |
| Language | Dart | 3.x |
| State Management | Riverpod | 2.4+ |
| Local Storage | Hive | 2.2+ |
| Secure Storage | flutter_secure_storage | 9.0+ |
| GraphQL Client | graphql_flutter | 5.1+ |
| HTTP Client | dio | 5.4+ |
| Notifications | flutter_local_notifications | 16.0+ |
| Background Tasks | workmanager | 0.5+ |
| Testing | flutter_test, mocktail | Built-in, 1.0+ |

---

## Open Questions for Phase 1

**NEEDS CLARIFICATION** items resolved in this phase:
- ✅ State management choice: Riverpod
- ✅ Local database: Hive
- ✅ Background task execution: workmanager
- ✅ Offline support strategy: Cache-first
- ✅ Real-time subscriptions: GraphQL WebSocket with auto-reconnect

**No remaining technical unknowns.** Ready to proceed to Phase 1: Data Model & Contracts.
