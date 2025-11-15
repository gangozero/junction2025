# Feature Specification: Sauna Controller Application

**Feature Branch**: `001-sauna-controller-app`  
**Created**: 2025-11-15  
**Status**: Draft  
**Input**: User description: "I'm going to build flutter app for management of sauna controller through vendor api" (expanded to include web platform)

## Clarifications

### Session 2025-11-15

- Q: How should endpoint URLs be configured and discovered? → A: Runtime service discovery (fetch from https://prod.api.harvia.io/endpoints on startup, cache endpoints, separate REST/GraphQL services by function: generics for auth, device for controller config/shadow, data for state/events, with distinct HTTPS and WebSocket URLs per service)
- Q: How should the app handle the relationship between controllers and sensors? → A: Support both integrated and standalone sensors (flexible architecture for different hardware configs)
- Q: How should the app receive real-time status updates? → A: GraphQL subscriptions for live updates (WebSocket push notifications, instant updates)
- Q: Should the app support humidity monitoring and control? → A: Display humidity when available, no control (monitor-only for sensors that support it)
- Q: How should the app display event notifications from the Events Service? → A: All events with filtering (comprehensive event history with user-configurable filters)
- Q: Where should heating schedules be executed? → A: Local app scheduling with notifications (app sends commands at scheduled times, requires app running)
- Q: What scope of web platform support should be included? → A: Full feature parity with mobile (same capabilities across all platforms)
- Q: How should notifications work on web platform? → A: Browser notifications with graceful degradation (request permission, fall back to in-app alerts if denied)
- Q: How should scheduled heating execute on web platform? → A: Service worker with wake-up notifications (service worker attempts execution, sends notification to wake/open app if needed)
- Q: How should authentication tokens be stored securely on web? → A: Encrypted IndexedDB with session key (encrypt tokens in IndexedDB, derive encryption key from user session, clear on logout)
- Q: What responsive design approach should be used for web? → A: Responsive adaptive layout (mobile-first design that adapts to larger screens with side panels, multi-column layouts for desktop)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View and Monitor Sauna Status (Priority: P1)

A sauna owner wants to check the current status of their sauna remotely to see if it's heating, what the current temperature is, and whether it's ready to use. The app supports both controllers with integrated sensors and standalone sensors attached to sauna units.

**Why this priority**: Core value proposition - users need to see sauna status before taking any control actions. This is the foundation for all other features.

**Independent Test**: Can be fully tested by launching the app, authenticating with the vendor API, and viewing real-time sauna temperature, power state, and heating status on the main screen. Delivers immediate value by eliminating the need to physically check the sauna.

**Acceptance Scenarios**:

1. **Given** the user has opened the app and connected to their sauna, **When** they view the main dashboard, **Then** they see the current sauna temperature, target temperature, power status (on/off), and heating status from either the integrated controller sensor or linked standalone sensors, plus humidity level if the sensor supports it
2. **Given** the sauna is currently heating, **When** the user views the status screen, **Then** they see a clear indication that heating is in progress and estimated time to reach target temperature
3. **Given** the sauna state changes (temperature, power, errors), **When** the app has an active WebSocket subscription, **Then** updated status information appears instantly via push notification without manual refresh

---

### User Story 2 - Start and Stop Sauna Remotely (Priority: P2)

A sauna owner wants to turn the sauna on while driving home so it's ready when they arrive, and turn it off remotely if they forget.

**Why this priority**: Primary control function that delivers significant convenience value. Builds on P1 monitoring capability.

**Independent Test**: Can be fully tested by using the app to send power on/off commands through the vendor API and verifying the sauna responds appropriately. Delivers value by enabling remote sauna control from anywhere.

**Acceptance Scenarios**:

1. **Given** the sauna is currently off, **When** the user taps the "Start Sauna" button, **Then** the app sends a power-on command to the vendor API and shows confirmation when the sauna begins heating
2. **Given** the sauna is currently running, **When** the user taps the "Stop Sauna" button, **Then** the app sends a power-off command and shows confirmation when the sauna powers down
3. **Given** the user issues a control command, **When** the command is successfully processed, **Then** the app updates the status display to reflect the new state within 5 seconds

---

### User Story 3 - Adjust Sauna Temperature (Priority: P3)

A sauna owner wants to adjust the target temperature of their sauna to their preferred heat level without physically accessing the control panel.

**Why this priority**: Enhances control capabilities but depends on basic on/off functionality. Less critical than power control since temperature can often be set on the physical controller.

**Independent Test**: Can be fully tested by using the temperature adjustment controls in the app to set a new target temperature and verifying the sauna adjusts accordingly. Delivers value by allowing temperature customization remotely.

**Acceptance Scenarios**:

1. **Given** the sauna is running, **When** the user selects a new target temperature using the app controls, **Then** the app sends the temperature setting to the vendor API and the sauna begins adjusting to the new target
2. **Given** the user sets a temperature outside the safe operating range, **When** they attempt to confirm the setting, **Then** the app displays a warning and prevents setting an unsafe temperature
3. **Given** the user adjusts the temperature, **When** the command is successful, **Then** the app displays the new target temperature and shows progress toward reaching it

---

### User Story 4 - Authenticate and Connect to Sauna Controller (Priority: P1)

A sauna owner needs to securely connect the mobile app to their sauna controller through the vendor's API using their account credentials.

**Why this priority**: Essential prerequisite for all functionality - without authentication and connection, no other features can work.

**Independent Test**: Can be fully tested by entering valid credentials, successfully authenticating with the vendor API, and establishing a connection to the user's registered sauna controller. Delivers value by providing secure access to sauna controls.

**Acceptance Scenarios**:

1. **Given** the user has a valid account with the sauna vendor, **When** they enter their credentials and tap "Connect", **Then** the app authenticates with the vendor API and displays their registered sauna controllers
2. **Given** the user has multiple sauna controllers registered, **When** they successfully authenticate, **Then** the app displays a list of available controllers and allows selection
3. **Given** the user enters incorrect credentials, **When** they attempt to authenticate, **Then** the app displays a clear error message and allows retry without crashing

---

### User Story 5 - Set Sauna Heating Schedule (Priority: P4)

A sauna owner wants to schedule the sauna to automatically turn on and heat up at specific times (e.g., every evening at 6 PM) so it's ready when needed.

**Why this priority**: Convenience enhancement that requires all basic control features to be working. Nice-to-have but not essential for initial release.

**Independent Test**: Can be fully tested by creating a heating schedule in the app, verifying the schedule is saved, and confirming the sauna automatically starts at the scheduled time. Delivers value by automating routine sauna preparation.

**Acceptance Scenarios**:

1. **Given** the user is viewing the schedule screen, **When** they create a new scheduled heating time with target temperature, **Then** the schedule is saved locally and the app will send activation commands at the specified time when running
2. **Given** a schedule is active and the scheduled time arrives, **When** the app is running in foreground or background, **Then** the app sends a power-on command and temperature setting to the sauna controller
3. **Given** the user has created a schedule, **When** they want to disable it temporarily, **Then** they can toggle the schedule on/off without deleting it
4. **Given** a scheduled activation time approaches, **When** the app is not running, **Then** the user receives a notification reminder to open the app for scheduled activation

---

### User Story 6 - View Event Notifications and History (Priority: P3)

A sauna owner wants to receive notifications about important sauna events (errors, warnings, state changes) and review event history to understand what has happened with their sauna over time.

**Why this priority**: Safety and operational awareness - users need to be alerted to issues and be able to review event history for troubleshooting. Less critical than basic control but important for safe operation.

**Independent Test**: Can be fully tested by subscribing to the Events Service, triggering various sauna events, verifying notifications appear, and confirming the event history can be viewed and filtered. Delivers value by keeping users informed of sauna status and issues.

**Acceptance Scenarios**:

1. **Given** the app is running and subscribed to events, **When** a sauna event occurs (error, warning, state change), **Then** the user receives a push notification with event details
2. **Given** the user wants to review past events, **When** they open the event history screen, **Then** they see a chronological list of all events with timestamps, event types, and descriptions
3. **Given** the user wants to focus on specific event types, **When** they apply event filters (e.g., errors only, specific device), **Then** the event list updates to show only matching events

---

### Edge Cases

- What happens when the mobile device loses internet connectivity while controlling the sauna?
- How does the system handle situations where the vendor API is temporarily unavailable?
- What occurs when the WebSocket connection drops and real-time subscriptions are interrupted?
- How does the web app handle browser notification permission denial or blocking?
- What happens when a web service worker fails to execute a scheduled task due to browser resource limits?
- How does the app respond when IndexedDB is unavailable or quota exceeded on web platform?
- How does the app reconnect GraphQL subscriptions after the app is backgrounded and brought back to foreground?
- What occurs if the user tries to control a sauna that is already being controlled by someone else or another device?
- How does the app respond when the sauna controller is offline or unreachable?
- What happens if the user tries to set a heating schedule that conflicts with an existing schedule?
- What happens when a scheduled activation time arrives but the app is not running or has been force-closed?
- How does the system handle API rate limiting or throttling from the vendor?
- What occurs when the sauna reaches an error state (e.g., overheating, door open) while being controlled remotely?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to authenticate using their vendor API credentials
- **FR-002**: System MUST retrieve and display real-time sauna status information including current temperature, target temperature, power state, and heating status from both controllers with integrated sensors and standalone sensor devices, plus humidity readings when available from sensors that support it
- **FR-003**: System MUST allow users to send power on/off commands to the sauna controller through the vendor API
- **FR-004**: System MUST allow users to adjust the target temperature setting remotely
- **FR-005**: System MUST display confirmation when control commands are successfully processed
- **FR-006**: System MUST handle and display clear error messages when commands fail or the API is unreachable
- **FR-007**: System MUST use GraphQL WebSocket subscriptions to receive real-time status updates when sauna state changes (temperature, power, heating status, errors)
- **FR-008**: System MUST allow users to manually refresh the status display on demand
- **FR-009**: System MUST support connection to multiple sauna controllers if a user has more than one registered device
- **FR-019**: System MUST support displaying sensor data from standalone sensors that are not integrated into a controller
- **FR-023**: System MUST display humidity readings for sensors that provide humidity data, but MUST NOT provide humidity control functionality
- **FR-020**: System MUST automatically associate standalone sensors with their corresponding sauna controllers when both are present
- **FR-021**: System MUST allow users to manually link standalone sensors to controllers when automatic association is not available
- **FR-010**: System MUST allow users to create, view, edit, and delete heating schedules that are stored locally on the device
- **FR-029**: System MUST execute scheduled heating activations by sending control commands at the scheduled time when the app is running (foreground or background)
- **FR-030**: System MUST send notification reminders to users before scheduled activation times to ensure the app is available to execute the schedule
- **FR-011**: System MUST validate temperature settings to ensure they are within safe operating ranges for the sauna model
- **FR-012**: System MUST persist user authentication credentials securely (mobile: platform keychain/keystore via flutter_secure_storage, web: encrypted IndexedDB with session-derived key)
- **FR-013**: System MUST provide visual feedback during API communication (e.g., loading indicators)
- **FR-014**: System MUST display estimated time to reach target temperature when heating is in progress
- **FR-015**: System MUST handle network connectivity issues gracefully and notify users when offline
- **FR-022**: System MUST automatically reestablish GraphQL subscriptions when connectivity is restored after network interruption
- **FR-016**: System MUST prevent simultaneous conflicting commands (e.g., cannot set temperature while sauna is off)
- **FR-017**: System MUST display sauna controller error states and safety warnings when reported by the API
- **FR-024**: System MUST subscribe to the Events Service via GraphQL to receive real-time event notifications (errors, warnings, state changes, maintenance alerts)
- **FR-025**: System MUST display push notifications to users when critical events occur (mobile: local push notifications, web: browser notifications with permission request, fallback to in-app alerts if permission denied)
- **FR-026**: System MUST maintain a local event history showing all received events with timestamps, event types, and descriptions
- **FR-027**: System MUST allow users to filter event history by event type, severity, date range, and device
- **FR-028**: System MUST allow users to configure which event types trigger push notifications
- **FR-031**: System MUST implement responsive adaptive UI layout that adapts from mobile-first design to larger screens with side panels and multi-column layouts for desktop/tablet browsers
- **FR-018**: System MUST allow users to log out and disconnect from the vendor API

### Key Entities

- **Sauna Controller**: The physical sauna heater/control unit that connects to the vendor's cloud service. Has attributes including device ID, model, target temperature, power state, heating status, connection status, and error state. May have integrated sensors or rely on standalone sensors for temperature/humidity readings
- **Sensor Device**: A standalone sensor unit that provides telemetry data (temperature, humidity) for a sauna. Has attributes including device ID, sensor type, current readings (temperature always, humidity when supported), last update timestamp, battery level, and associated controller ID (if linked). Humidity is displayed when available but not controllable
- **User Account**: The sauna owner's account with the vendor's cloud service. Contains credentials for API authentication, linked sauna controllers, sensors, and user preferences
- **Heating Schedule**: A user-defined automation rule specifying when the sauna should automatically start heating. Stored locally on the device. Includes attributes like scheduled time, target temperature, days of week, enabled/disabled status, and last execution timestamp. Mobile: requires the app to be running (foreground or background) to execute. Web: service worker attempts execution even when tab is closed, sends wake-up notification if app needs to be active
- **API Session**: The authenticated connection between the app and vendor API. Maintains authentication token, session expiration, and connection state. Mobile: tokens stored in platform keychain/keystore. Web: tokens encrypted in IndexedDB with session-derived key, cleared on logout
- **Event**: A notification or alert from the Events Service about sauna operational status. Has attributes including event ID, timestamp, event type (error, warning, info, state change), severity level, device ID, description, and acknowledgment status
- **Command Request**: A control action sent from the app to the sauna controller via the vendor API. Includes command type (power, temperature, schedule), parameters, timestamp, and success/failure status

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view current sauna status (temperature, power state) within 3 seconds of opening the app
- **SC-002**: Control commands (power on/off, temperature adjustment) execute and receive confirmation within 5 seconds under normal network conditions
- **SC-003**: 95% of users successfully authenticate and connect to their sauna controller on first attempt
- **SC-004**: App handles network interruptions gracefully, with clear offline indicators and automatic reconnection when connectivity resumes
- **SC-005**: Users can complete the full workflow from app launch to starting their sauna in under 30 seconds
- **SC-006**: Scheduled heating activations occur within 1 minute of the scheduled time when the app is running in foreground or background
- **SC-007**: Status updates are pushed to the app instantly (within 2 seconds) via GraphQL subscriptions when sauna state changes
- **SC-008**: App successfully prevents 100% of unsafe temperature settings outside the sauna's operating range
- **SC-009**: Error messages are displayed within 2 seconds when API requests fail, with clear user-friendly explanations
- **SC-010**: Users can switch between multiple sauna controllers in under 5 seconds if they have more than one device
- **SC-011**: Critical event notifications are delivered to users within 3 seconds of the event occurring
- **SC-012**: Event history displays at least the most recent 1000 events with filter results appearing within 1 second
