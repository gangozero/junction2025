# Tasks: Sauna Controller Application

**Feature Branch**: `001-sauna-controller-app`  
**Input**: Design documents from `/specs/001-sauna-controller-app/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/api-contracts.md ✅

**Target Platforms**: iOS 13+, Android 8.0+ (API 26+), Web (modern browsers)  
**Tech Stack**: Flutter 3.16+ / Dart 3.x, Riverpod, Hive, graphql_flutter, workmanager

**Tests**: Not explicitly requested in spec - tasks focus on implementation only.

**Organization**: Tasks grouped by user story for independent implementation and incremental delivery.

---

## Format: `- [ ] [ID] [P?] [Story?] Description`

- **Checkbox**: `- [ ]` for tracking completion
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3, US4, US5, US6) - omit for Setup/Foundational/Polish phases
- **File paths**: Exact paths from plan.md structure

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Initialize Flutter project with all platforms and dependencies

- [ ] T001 Create Flutter project structure with web support enabled using `flutter create --platforms=ios,android,web harvia_msga`
- [ ] T002 Configure pubspec.yaml with dependencies (riverpod 2.4+, graphql_flutter 5.1+, hive 2.2+, dio 5.4+, flutter_secure_storage 9.0+, flutter_local_notifications 16.0+, workmanager 0.5+)
- [ ] T003 [P] Setup iOS configuration in ios/Runner/Info.plist (background modes, notification permissions, network permissions)
- [ ] T004 [P] Setup Android configuration in android/app/src/main/AndroidManifest.xml (permissions, workmanager, notification channels)
- [ ] T005 [P] Setup web configuration in web/index.html and web/manifest.json (PWA settings, service worker registration)
- [ ] T006 [P] Create project directory structure per plan.md (lib/core/, lib/features/, lib/services/, lib/shared/)
- [ ] T007 [P] Configure analysis_options.yaml with strict linting rules for Flutter/Dart
- [ ] T008 Create lib/core/constants/api_constants.dart with Harvia API endpoint configuration

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure required before ANY user story can be implemented

**⚠️ CRITICAL**: All user stories depend on this phase - must complete before story work begins

- [ ] T009 Create error handling framework in lib/core/error/failures.dart (NetworkFailure, AuthFailure, ApiFailure, CacheFailure classes)
- [ ] T010 [P] Create logging utility in lib/core/utils/logger.dart with platform-specific implementations
- [ ] T011 [P] Setup Hive initialization and encryption in lib/services/storage/hive_service.dart
- [ ] T012 [P] Setup platform-specific secure storage wrapper in lib/services/storage/secure_storage_service.dart (flutter_secure_storage for mobile, encrypted IndexedDB for web)
- [ ] T013 Create GraphQL client configuration in lib/services/api/graphql/graphql_client.dart with WebSocket support and auto-reconnection
- [ ] T014 [P] Create REST API client in lib/services/api/rest/rest_client.dart using dio with interceptors
- [ ] T015 Create base repository pattern in lib/core/data/base_repository.dart with error handling and offline-first strategy
- [ ] T016 [P] Create app theme configuration in lib/core/theme/app_theme.dart with responsive breakpoints for web
- [ ] T017 [P] Setup responsive layout utilities in lib/core/utils/responsive.dart (mobile, tablet, desktop breakpoints)
- [ ] T018 [P] Create platform detection utility in lib/core/utils/platform_utils.dart (mobile vs web feature flags)
- [ ] T019 [P] Setup notification service wrapper in lib/services/notifications/notification_service.dart (flutter_local_notifications for mobile, browser notifications with permission handling for web)
- [ ] T020 [P] Setup background task service in lib/services/background/background_service.dart (workmanager for mobile, service worker for web)
- [ ] T021 Create navigation/routing configuration in lib/core/router/app_router.dart using Flutter navigation 2.0
- [ ] T022 Create shared widget components in lib/shared/widgets/ (loading_indicator.dart, error_display.dart, responsive_layout.dart)

**Checkpoint**: ✅ Foundation complete - user story implementation can now begin in parallel

---

## Phase 3: User Story 4 - Authentication (Priority: P1) 🎯 MVP Foundation

**Goal**: Secure authentication and session management across mobile and web platforms

**Independent Test**: Launch app, enter credentials, successfully authenticate, see device list, logout and verify session cleared

### Implementation for US4

- [ ] T023 [P] [US4] Create UserAccount entity model in lib/features/auth/domain/entities/user_account.dart
- [ ] T024 [P] [US4] Create APISession entity model in lib/features/auth/domain/entities/api_session.dart
- [ ] T025 [P] [US4] Create auth DTOs in lib/features/auth/data/models/ (login_request.dart, token_response.dart, refresh_request.dart)
- [ ] T026 [US4] Create auth repository interface in lib/features/auth/domain/repositories/auth_repository.dart
- [ ] T027 [US4] Implement auth API data source in lib/features/auth/data/datasources/auth_remote_datasource.dart (POST /auth/token, /auth/refresh, /auth/revoke)
- [ ] T028 [US4] Implement auth repository in lib/features/auth/data/repositories/auth_repository_impl.dart with token refresh logic
- [ ] T029 [US4] Create auth state notifier in lib/features/auth/presentation/providers/auth_provider.dart using Riverpod StateNotifier
- [ ] T030 [US4] Create login screen UI in lib/features/auth/presentation/screens/login_screen.dart with responsive layout
- [ ] T031 [US4] Create login form widgets in lib/features/auth/presentation/widgets/ (email_field.dart, password_field.dart, login_button.dart)
- [ ] T032 [US4] Implement automatic token refresh interceptor in lib/services/api/rest/auth_interceptor.dart
- [ ] T033 [US4] Implement secure token storage (mobile: keychain/keystore, web: encrypted IndexedDB) in lib/features/auth/data/datasources/auth_local_datasource.dart
- [ ] T034 [US4] Add logout functionality with token revocation and local data cleanup
- [ ] T035 [US4] Create auth error handling and user-friendly error messages

**Checkpoint**: ✅ Authentication complete - users can securely log in/out across all platforms

---

## Phase 4: User Story 1 - Status Monitoring (Priority: P1) 🎯 MVP Core

**Goal**: Real-time sauna status display with sensor support and WebSocket subscriptions

**Independent Test**: After login, view dashboard showing sauna temperature, power state, heating status, humidity (if available), with live updates via GraphQL subscriptions

### Implementation for US1

- [ ] T036 [P] [US1] Create SaunaController entity in lib/features/device/domain/entities/sauna_controller.dart with enums (PowerState, HeatingStatus, ConnectionStatus)
- [ ] T037 [P] [US1] Create SensorDevice entity in lib/features/device/domain/entities/sensor_device.dart
- [ ] T038 [P] [US1] Create device DTOs in lib/features/device/data/models/ (device_dto.dart, sensor_dto.dart mapping from GraphQL responses)
- [ ] T039 [US1] Create device repository interface in lib/features/device/domain/repositories/device_repository.dart
- [ ] T040 [US1] Implement GraphQL device data source in lib/features/device/data/datasources/device_remote_datasource.dart (listDevices query, getDeviceState query, onDeviceStateChange subscription)
- [ ] T041 [US1] Implement device cache data source in lib/features/device/data/datasources/device_local_datasource.dart using Hive
- [ ] T042 [US1] Implement device repository in lib/features/device/data/repositories/device_repository_impl.dart with cache-first offline strategy
- [ ] T043 [US1] Create device list state provider in lib/features/dashboard/presentation/providers/device_list_provider.dart
- [ ] T044 [US1] Create device state stream provider in lib/features/dashboard/presentation/providers/device_state_provider.dart for WebSocket subscriptions
- [ ] T045 [US1] Create dashboard screen in lib/features/dashboard/presentation/screens/dashboard_screen.dart with responsive layout (mobile: single column, web: multi-column grid)
- [ ] T046 [P] [US1] Create device status card widget in lib/features/dashboard/presentation/widgets/device_status_card.dart
- [ ] T047 [P] [US1] Create temperature display widget in lib/features/dashboard/presentation/widgets/temperature_display.dart with progress indicator
- [ ] T048 [P] [US1] Create humidity display widget (conditional) in lib/features/dashboard/presentation/widgets/humidity_display.dart
- [ ] T049 [P] [US1] Create heating status indicator in lib/features/dashboard/presentation/widgets/heating_status.dart
- [ ] T050 [US1] Implement GraphQL sensor data source in lib/features/device/data/datasources/sensor_remote_datasource.dart (getLatestData query, onSensorData subscription)
- [ ] T051 [US1] Implement automatic sensor-controller association logic in lib/features/device/domain/usecases/associate_sensors_usecase.dart
- [ ] T052 [US1] Add manual sensor linking UI in lib/features/device/presentation/widgets/sensor_link_dialog.dart
- [ ] T053 [US1] Implement pull-to-refresh for manual status updates
- [ ] T054 [US1] Add connection status indicators and offline mode handling
- [ ] T055 [US1] Implement WebSocket reconnection logic with exponential backoff

**Checkpoint**: ✅ Status monitoring complete - users can view real-time sauna state with sensors

---

## Phase 5: User Story 2 - Remote Control (Priority: P2)

**Goal**: Send power on/off commands to sauna controller

**Independent Test**: From dashboard, tap power button, verify command sent via GraphQL mutation, see confirmation and status update

### Implementation for US2

- [ ] T056 [P] [US2] Create CommandRequest entity in lib/features/control/domain/entities/command_request.dart
- [ ] T057 [P] [US2] Create command DTOs in lib/features/control/data/models/ (power_command_dto.dart, command_response_dto.dart)
- [ ] T058 [US2] Create control repository interface in lib/features/control/domain/repositories/control_repository.dart
- [ ] T059 [US2] Implement GraphQL control data source in lib/features/control/data/datasources/control_remote_datasource.dart (sendDeviceCommand mutation for power on/off)
- [ ] T060 [US2] Implement control repository in lib/features/control/data/repositories/control_repository_impl.dart with retry logic
- [ ] T061 [US2] Create command queue for offline operation in lib/features/control/data/datasources/control_local_datasource.dart using Hive
- [ ] T062 [US2] Create control state provider in lib/features/control/presentation/providers/control_provider.dart
- [ ] T063 [US2] Create power control widget in lib/features/control/presentation/widgets/power_control.dart with loading states
- [ ] T064 [US2] Add command confirmation feedback (success/error snackbars)
- [ ] T065 [US2] Implement optimistic UI updates (show expected state immediately, rollback on failure)
- [ ] T066 [US2] Add validation to prevent commands when sauna is offline

**Checkpoint**: ✅ Remote control complete - users can power sauna on/off remotely

---

## Phase 6: User Story 3 - Temperature Adjustment (Priority: P3)

**Goal**: Adjust target temperature with validation and safety checks

**Independent Test**: From dashboard, use temperature controls to set new target, verify command sent, see updated target and progress

### Implementation for US3

- [ ] T067 [P] [US3] Create temperature command DTO in lib/features/control/data/models/temperature_command_dto.dart
- [ ] T068 [US3] Add temperature mutation to control data source in lib/features/control/data/datasources/control_remote_datasource.dart
- [ ] T069 [US3] Create temperature validation use case in lib/features/control/domain/usecases/validate_temperature_usecase.dart (check model-specific safe ranges)
- [ ] T070 [US3] Create temperature control widget in lib/features/control/presentation/widgets/temperature_control.dart (slider + input field)
- [ ] T071 [US3] Add temperature range validation UI with warning dialogs
- [ ] T072 [US3] Show estimated time to reach target temperature calculation
- [ ] T073 [US3] Prevent temperature adjustment when sauna is powered off
- [ ] T074 [US3] Add temperature presets for common settings (60°C, 70°C, 80°C, 90°C)

**Checkpoint**: ✅ Temperature control complete - users can safely adjust sauna temperature

---

## Phase 7: User Story 6 - Event Notifications (Priority: P3)

**Goal**: Real-time event notifications and filterable event history

**Independent Test**: Subscribe to events, trigger sauna events (error, state change), verify notifications appear (mobile: local push, web: browser notification or in-app), view and filter event history

### Implementation for US6

- [ ] T075 [P] [US6] Create Event entity in lib/features/events/domain/entities/event.dart with enums (EventType, Severity)
- [ ] T076 [P] [US6] Create event DTOs in lib/features/events/data/models/ (event_dto.dart mapping from GraphQL)
- [ ] T077 [US6] Create events repository interface in lib/features/events/domain/repositories/events_repository.dart
- [ ] T078 [US6] Implement GraphQL events data source in lib/features/events/data/datasources/events_remote_datasource.dart (listEvents query with filters, onEvent subscription)
- [ ] T079 [US6] Implement events cache in lib/features/events/data/datasources/events_local_datasource.dart with ring buffer (max 1000 events) using Hive
- [ ] T080 [US6] Implement events repository in lib/features/events/data/repositories/events_repository_impl.dart
- [ ] T081 [US6] Create event stream provider in lib/features/events/presentation/providers/events_provider.dart for WebSocket subscriptions
- [ ] T082 [US6] Implement platform-specific notification dispatcher in lib/services/notifications/event_notification_handler.dart (mobile: flutter_local_notifications, web: browser notifications with permission request + in-app fallback)
- [ ] T083 [US6] Create event history screen in lib/features/events/presentation/screens/events_screen.dart with responsive list (mobile: single column, web: table view)
- [ ] T084 [P] [US6] Create event filter widget in lib/features/events/presentation/widgets/event_filter.dart (type, severity, date range, device)
- [ ] T085 [P] [US6] Create event list item widget in lib/features/events/presentation/widgets/event_list_item.dart
- [ ] T086 [US6] Create notification settings screen in lib/features/events/presentation/screens/notification_settings_screen.dart for configuring which event types trigger notifications
- [ ] T087 [US6] Implement browser notification permission request flow for web platform
- [ ] T088 [US6] Add event acknowledgment functionality

**Checkpoint**: ✅ Events complete - users receive notifications and can review filtered history

---

## Phase 8: User Story 5 - Scheduling (Priority: P4)

**Goal**: Create, manage, and execute heating schedules with platform-specific background execution

**Independent Test**: Create schedule for future time, verify saved locally, confirm app sends commands at scheduled time (mobile: via workmanager, web: via service worker with wake notification)

### Implementation for US5

- [ ] T089 [P] [US5] Create HeatingSchedule entity in lib/features/schedule/domain/entities/heating_schedule.dart
- [ ] T090 [P] [US5] Create schedule DTOs in lib/features/schedule/data/models/schedule_dto.dart with Hive type adapter
- [ ] T091 [US5] Create schedule repository interface in lib/features/schedule/domain/repositories/schedule_repository.dart
- [ ] T092 [US5] Implement schedule local data source in lib/features/schedule/data/datasources/schedule_local_datasource.dart using Hive (local-only storage)
- [ ] T093 [US5] Implement schedule repository in lib/features/schedule/data/repositories/schedule_repository_impl.dart
- [ ] T094 [US5] Create schedule state provider in lib/features/schedule/presentation/providers/schedule_provider.dart
- [ ] T095 [US5] Implement mobile background scheduler in lib/services/background/mobile_scheduler.dart using workmanager
- [ ] T096 [US5] Implement web service worker scheduler in web/service_worker.js with wake-up notifications
- [ ] T096a [US5] Create web service worker implementation in web/service_worker.js (schedule execution logic, notification handling, wake-up events)
- [ ] T097 [US5] Create schedule execution coordinator in lib/features/schedule/domain/usecases/execute_schedule_usecase.dart (calls control repository to send power/temp commands)
- [ ] T098 [US5] Create schedule list screen in lib/features/schedule/presentation/screens/schedule_list_screen.dart with responsive layout
- [ ] T099 [US5] Create schedule form screen in lib/features/schedule/presentation/screens/schedule_form_screen.dart (add/edit)
- [ ] T100 [P] [US5] Create time picker widget in lib/features/schedule/presentation/widgets/time_picker.dart
- [ ] T101 [P] [US5] Create day selector widget in lib/features/schedule/presentation/widgets/day_selector.dart
- [ ] T102 [P] [US5] Create schedule card widget in lib/features/schedule/presentation/widgets/schedule_card.dart with enable/disable toggle
- [ ] T103 [US5] Implement reminder notifications before scheduled activation time
- [ ] T104 [US5] Add conflict detection for overlapping schedules
- [ ] T105 [US5] Handle web service worker limitations and graceful degradation
- [ ] T106 [US5] Add cross-platform validation for schedule execution (verify workmanager on mobile, service worker on web)

**Checkpoint**: ✅ Scheduling complete - users can automate sauna heating across platforms

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple features and platforms

- [ ] T107 [P] Implement comprehensive offline mode with sync queue across all features
- [ ] T107 [P] Add loading skeletons for all async data in lib/shared/widgets/skeleton_loader.dart
- [ ] T108 [P] Implement responsive navigation (mobile: bottom nav, tablet/desktop: side rail) in lib/core/router/responsive_navigation.dart
- [ ] T109 [P] Add app settings screen in lib/features/settings/presentation/screens/settings_screen.dart (units, theme, language)
- [ ] T110 Add user profile screen with account management
- [ ] T111 Implement proper error boundary widgets for each feature
- [ ] T112 Add analytics event tracking (platform-specific: Firebase for mobile, Google Analytics for web)
- [ ] T113 [P] Performance optimization: implement lazy loading for device/event lists
- [ ] T114 [P] Accessibility improvements: screen reader support, semantic labels, keyboard navigation for web
- [ ] T115 Add deep linking support for direct navigation to devices/schedules
- [ ] T116 Implement app lifecycle handling for subscription management (pause on background, resume on foreground)
- [ ] T117 Add platform-specific polish (iOS: Cupertino widgets, Android: Material3, Web: hover states)
- [ ] T118 Create app onboarding flow for first-time users
- [ ] T119 Add rate limiting protection with exponential backoff for all API calls
- [ ] T120 Security audit: validate all user inputs, sanitize display data, check token expiry
- [ ] T121 [P] Create README.md with build instructions for all platforms per quickstart.md
- [ ] T122 [P] Document API integration patterns in docs/api-integration.md
- [ ] T123 Run final validation of quickstart.md instructions on clean environment
- [ ] T124 Create release build configurations for iOS, Android, and Web

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Phase 1 (Setup)**: No dependencies - START HERE
2. **Phase 2 (Foundational)**: Depends on Phase 1 completion - BLOCKS all user stories
3. **Phase 3 (US4 - Auth)**: Depends on Phase 2 - Must complete before other user stories
4. **Phase 4 (US1 - Status)**: Depends on Phases 2 & 3 - Core monitoring capability
5. **Phase 5 (US2 - Control)**: Depends on Phases 2, 3 & 4 - Builds on monitoring
6. **Phase 6 (US3 - Temperature)**: Depends on Phases 2, 3, 4 & 5 - Extends control
7. **Phase 7 (US6 - Events)**: Depends on Phases 2 & 3 - Independent of control features
8. **Phase 8 (US5 - Scheduling)**: Depends on Phases 2, 3 & 5 - Requires control repository
9. **Phase 9 (Polish)**: Depends on all desired user stories being complete

### Critical Path for MVP

**MVP = US4 (Auth) + US1 (Status) + US2 (Control)**

```
T001-T008 (Setup)
    ↓
T009-T022 (Foundational) ← BLOCKING GATE
    ↓
T023-T035 (US4: Auth) ← REQUIRED FOR MVP
    ↓
T036-T055 (US1: Status) ← REQUIRED FOR MVP
    ↓
T056-T066 (US2: Control) ← REQUIRED FOR MVP
    ↓
MVP COMPLETE ✅
```

### User Story Dependencies

- **US4 (Auth - P1)**: No dependencies on other stories - can start after Foundational
- **US1 (Status - P1)**: Depends on US4 (auth tokens needed) - can run parallel with US6 if staffed
- **US2 (Control - P2)**: Depends on US4 + US1 (needs auth + device state)
- **US3 (Temperature - P3)**: Depends on US4 + US1 + US2 (extends control capability)
- **US6 (Events - P3)**: Depends on US4 only - INDEPENDENT of US1/US2/US3 (can run parallel)
- **US5 (Scheduling - P4)**: Depends on US4 + US2 (needs auth + control repository)

### Parallel Opportunities

**Within Setup (Phase 1)**:
- T003 (iOS config), T004 (Android config), T005 (Web config) can run in parallel
- T006 (directory structure), T007 (linting), T008 (constants) can run in parallel

**Within Foundational (Phase 2)**:
- T010, T011, T012, T014, T016, T017, T018, T019, T020, T022 can all run in parallel
- T013 depends on T012 (secure storage needed for tokens)

**Within User Stories**:
- Entity models (marked [P]) can run in parallel
- Widgets (marked [P]) can run in parallel
- Data sources can run parallel if they don't share dependencies

**Across User Stories** (if team has capacity):
- After US4 completes: US1 and US6 can run in parallel
- After US1 completes: US2 and continue US6 in parallel
- After US2 completes: US3 and US5 can run in parallel (if US6 is also done)

### Within Each User Story

**Standard execution order within a story**:
1. Entities and DTOs (can run in parallel)
2. Repository interface
3. Data sources (remote and local can run parallel)
4. Repository implementation
5. State providers
6. UI screens and widgets (widgets can run parallel)
7. Integration and polish

---

## Parallel Example: User Story 4 (Auth)

**Fully parallel tasks** (can all start simultaneously after T022):
```bash
T023 (UserAccount entity)  
T024 (APISession entity)   } All independent, different files
T025 (Auth DTOs)           
```

**Next wave** (after T025 completes):
```bash
T026 (Repository interface) ← needs entities
    ↓
T027 (Remote datasource)    } Can run parallel
T033 (Local datasource)     
    ↓
T028 (Repository impl) ← needs datasources
    ↓
T029 (State provider) ← needs repository
    ↓
T030 (Login screen)   } Can run parallel
T031 (Form widgets)   
T032 (Interceptor)    
    ↓
T034 (Logout) + T035 (Error handling) ← final integration
```

---

## Implementation Strategy

### MVP-First Approach

**Week 1-2: Foundation + Auth + Status**
- Complete Setup (T001-T008)
- Complete Foundational (T009-T022)
- Complete US4 Auth (T023-T035)
- Complete US1 Status (T036-T055)
- **Deliverable**: Users can log in and view real-time sauna status

**Week 3: Control**
- Complete US2 Power Control (T056-T066)
- Start US3 Temperature (T067-T074)
- **Deliverable**: Users can remotely control their sauna

**Week 4: Enhancement**
- Complete US3 Temperature (if not done)
- Complete US6 Events (T075-T088)
- Start US5 Scheduling (T089-T105)
- **Deliverable**: Full-featured app with notifications

**Week 5+: Polish & Release**
- Complete US5 Scheduling (if not done)
- Complete Polish (T106-T124)
- **Deliverable**: Production-ready application

### Platform Parity Notes

All user stories deliver identical functionality across iOS, Android, and Web. Platform-specific implementations are abstracted in:
- **Storage**: T012 (mobile: keychain/keystore, web: encrypted IndexedDB)
- **Notifications**: T019, T082 (mobile: local push, web: browser notifications + fallback)
- **Background Tasks**: T020, T095, T096 (mobile: workmanager, web: service worker)
- **UI Layout**: T017, T045, T083, T098 (responsive breakpoints for mobile/tablet/desktop)

### Testing Checkpoints

After each phase, validate using the "Independent Test" criteria from spec.md:
- **Phase 3 (US4)**: Can log in/out successfully
- **Phase 4 (US1)**: Can view live sauna status with sensors
- **Phase 5 (US2)**: Can turn sauna on/off remotely
- **Phase 6 (US3)**: Can adjust temperature safely
- **Phase 7 (US6)**: Receive event notifications and filter history
- **Phase 8 (US5)**: Schedules execute at specified times

---

## Task Summary

- **Total Tasks**: 126
- **Setup Tasks**: 8 (T001-T008)
- **Foundational Tasks**: 14 (T009-T022)
- **User Story 4 (Auth - P1)**: 13 tasks (T023-T035) - MVP Foundation
- **User Story 1 (Status - P1)**: 20 tasks (T036-T055) - MVP Core
- **User Story 2 (Control - P2)**: 11 tasks (T056-T066) - MVP
- **User Story 3 (Temperature - P3)**: 8 tasks (T067-T074)
- **User Story 6 (Events - P3)**: 14 tasks (T075-T088)
- **User Story 5 (Scheduling - P4)**: 19 tasks (T089-T107) - includes T096a and T106
- **Polish**: 19 tasks (T108-T126)

**Parallel Opportunities Identified**: 47 tasks marked [P] can run in parallel with others in their phase

**MVP Scope** (Recommended first release):
- Setup + Foundational: 22 tasks
- US4 (Auth): 13 tasks  
- US1 (Status): 20 tasks
- US2 (Control): 11 tasks
- **MVP Total**: 66 tasks

**Post-MVP Features**:
- US3 (Temperature): 8 tasks
- US6 (Events): 14 tasks
- US5 (Scheduling): 19 tasks
- Polish: 19 tasks
- **Enhancement Total**: 60 tasks

---

**Generated**: 2025-11-15  
**Branch**: 001-sauna-controller-app  
**Status**: Ready for implementation  
**Next Step**: Begin with Phase 1 (Setup) tasks T001-T008
