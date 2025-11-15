# Implementation Plan: Sauna Controller Application

**Branch**: `001-sauna-controller-app` | **Date**: 2025-11-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-sauna-controller-app/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a Flutter cross-platform application for iOS, Android, and Web that enables remote management of Harvia sauna controllers through the vendor's cloud API. Users will authenticate, monitor real-time sauna status (temperature, humidity, power state), send control commands (power on/off, temperature adjustment), manage heating schedules locally, and receive event notifications. The app integrates with Harvia's GraphQL API for real-time subscriptions via WebSocket, REST API for authentication and commands, and supports both controllers with integrated sensors and standalone sensor devices. Web platform provides full feature parity with mobile using responsive adaptive layouts, browser notifications, service workers for scheduling, and encrypted IndexedDB for secure storage.

## Technical Context

**Language/Version**: Dart 3.x with Flutter 3.16+ (stable channel)  
**Primary Dependencies**: 
- `riverpod` 2.4+ for state management (see research.md)
- `graphql_flutter` 5.1+ for GraphQL client with WebSocket subscriptions
- `dio` 5.4+ for REST API calls
- `flutter_secure_storage` 9.0+ for secure credential storage (mobile: keychain/keystore, web: encrypted IndexedDB)
- `flutter_local_notifications` 16.0+ for push notifications (mobile only, web uses browser notifications)
- `workmanager` 0.5+ for background task scheduling (mobile only, web uses service workers)
- `hive` 2.2+ for local database (see research.md)

**Storage**: 
- Secure storage for authentication tokens: mobile (flutter_secure_storage), web (encrypted IndexedDB with session key)
- Local database for event history and schedules: Hive with encryption
- Shared preferences for user settings

**Testing**: 
- `flutter_test` for unit and widget tests
- `integration_test` for end-to-end testing
- `mockito` or `mocktail` for mocking API calls

**Target Platform**: iOS 13+, Android 8.0+ (API level 26+), Web (modern browsers: Chrome, Firefox, Safari, Edge)

**Project Type**: Cross-platform application (iOS + Android + Web)

**Performance Goals**: 
- App launch to dashboard: <3 seconds
- API response rendering: <2 seconds
- WebSocket subscription reconnection: <5 seconds
- Event filter application: <1 second
- 60fps UI animations and scrolling

**Constraints**: 
- Real-time updates via GraphQL subscriptions (2-second latency max)
- Offline-capable for viewing cached status and schedules
- Background task execution: mobile (workmanager), web (service workers with browser limitations)
- Secure credential storage: mobile (platform keychain/keystore), web (encrypted IndexedDB)
- Responsive UI with mobile-first design adapting to desktop layouts
- App size: <50MB (mobile), initial web bundle <2MB
- Browser notification permission required for web push notifications

**Scale/Scope**: 
- Support 1-10 sauna controllers per user
- Event history: 1000+ events locally cached
- Target users: <10,000 initially
- 5-6 main screens (auth, dashboard, device list, schedule, events, settings)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitution Status**: Template constitution found - no specific project principles defined yet.

Since the constitution file contains only template placeholders, no specific gates can be evaluated. The project will proceed with standard mobile app development best practices:

✅ **General Best Practices Applied**:
- Feature-based module architecture
- Clear separation of concerns (UI, business logic, data layer)
- Comprehensive testing strategy (unit, widget, integration)
- Secure credential storage
- Error handling and offline support

⚠️ **Note**: Once project-specific constitution principles are defined, this section should be updated to reflect compliance checks against those principles.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Cross-Platform Structure (Flutter application)
lib/
├── main.dart                    # App entry point
├── core/
│   ├── constants/              # API endpoints, app constants
│   ├── theme/                  # App theming and styles
│   ├── utils/                  # Helper functions, extensions
│   └── error/                  # Error handling, exceptions
├── features/
│   ├── auth/
│   │   ├── data/              # API clients, repositories
│   │   ├── domain/            # Models, use cases
│   │   └── presentation/      # Screens, widgets, state
│   ├── dashboard/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── device/
│   │   ├── data/              # Device/sensor management
│   │   ├── domain/
│   │   └── presentation/
│   ├── control/
│   │   ├── data/              # Power, temperature control
│   │   ├── domain/
│   │   └── presentation/
│   ├── schedule/
│   │   ├── data/              # Local scheduling, notifications
│   │   ├── domain/
│   │   └── presentation/
│   └── events/
│       ├── data/              # Event subscriptions, history
│       ├── domain/
│       └── presentation/
├── services/
│   ├── api/
│   │   ├── graphql/          # GraphQL client, subscriptions
│   │   ├── rest/             # REST API client
│   │   └── websocket/        # WebSocket management
│   ├── storage/              # Secure storage, local DB
│   ├── notifications/        # Push notifications
│   └── background/           # Background tasks
└── shared/
    ├── widgets/              # Reusable UI components
    └── models/               # Shared data models

test/
├── unit/                     # Unit tests for business logic
├── widget/                   # Widget tests for UI components
└── integration/              # End-to-end integration tests

android/                      # Android-specific configuration
ios/                          # iOS-specific configuration
web/                          # Web-specific configuration
├── index.html                # Web entry point
├── manifest.json             # PWA manifest
└── service_worker.js         # Service worker for scheduling and notifications
```

**Structure Decision**: Selected cross-platform application structure with feature-based modularization. Each feature (auth, dashboard, device, control, schedule, events) follows clean architecture with data/domain/presentation layers. Platform-specific implementations abstracted in service layer (storage, notifications, background tasks). This supports independent development and testing of user stories, clear separation of concerns, platform parity, and scalability as features grow.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: No complexity violations identified. Project follows standard Flutter mobile app patterns with feature-based architecture. No constitution-specific violations to justify since constitution principles are not yet defined for this project.

---

## Planning Summary

### Phase 0: Research (Complete ✅)

**Output**: [research.md](research.md)

All technical unknowns resolved:
- ✅ State management: Riverpod selected for type-safety and async support
- ✅ Local storage: Hive selected for performance and simplicity
- ✅ GraphQL client: graphql_flutter with WebSocket subscriptions
- ✅ Background tasks: workmanager for cross-platform scheduling
- ✅ Real-time updates: GraphQL subscriptions with auto-reconnect
- ✅ Offline support: Cache-first strategy with background sync
- ✅ Security: flutter_secure_storage for token management

### Phase 1: Design (Complete ✅)

**Outputs**: 
- [data-model.md](data-model.md) - 7 core entities with full specifications
- [contracts/api-contracts.md](contracts/api-contracts.md) - Complete API integration contracts
- [quickstart.md](quickstart.md) - Developer onboarding guide

**Entities Defined**:
1. User Account - Cloud authentication and profile
2. Sauna Controller - Physical device state and control
3. Sensor Device - Standalone and integrated sensor telemetry
4. Heating Schedule - Local schedule storage and execution
5. API Session - Token management and session state
6. Event - Real-time event stream and history
7. Command Request - Control command queue and retry logic

**API Services Mapped**:
- REST API: Authentication (login, refresh, logout)
- GraphQL Device Service: Device queries, mutations, subscriptions
- GraphQL Data Service: Sensor telemetry queries and subscriptions
- GraphQL Events Service: Event queries and real-time subscriptions

### Technology Decisions Summary

| Category | Decision | Rationale |
|----------|----------|-----------||
| Framework | Flutter 3.16+ | Cross-platform iOS/Android/Web with single codebase |
| Language | Dart 3.x | Type-safe, null-safe, excellent performance across platforms |
| State | Riverpod | Compile-time safety, testability, async support |
| Storage | Hive | Pure Dart, fast, encrypted support |
| API | GraphQL + REST | Real-time subscriptions + authentication |
| Notifications | flutter_local_notifications + browser API | Mobile: local push, Web: browser notifications with fallback |
| Background | workmanager + service workers | Mobile: native background tasks, Web: service workers |
| Security | flutter_secure_storage + IndexedDB | Mobile: keychain/keystore, Web: encrypted IndexedDB |
| Responsive UI | MediaQuery + LayoutBuilder | Mobile-first adaptive layouts for all screen sizes |

### Architecture Highlights

**Clean Architecture Pattern**:
- **Presentation Layer**: Flutter widgets, Riverpod providers
- **Domain Layer**: Business logic, entities, use cases
- **Data Layer**: API clients, repositories, local storage

**Key Architectural Decisions**:
1. Feature-based modularization for independent development
2. GraphQL subscriptions for real-time updates (not polling)
3. Local-first scheduling with notification reminders
4. Cache-first offline support with background sync
5. Automatic sensor-controller association with manual override
6. Exponential backoff for API errors and reconnections

### Implementation Readiness

✅ **Ready to Proceed to Phase 2**

All planning prerequisites complete:
- Technical unknowns resolved
- Data model fully specified
- API contracts documented
- Development environment guide created
- Architecture decisions made
- Agent context updated

### Next Steps

1. **Review Planning Artifacts**:
   - Read research.md for technology justifications
   - Study data-model.md for entity relationships
   - Review contracts/api-contracts.md for API details
   - Follow quickstart.md for environment setup

2. **Proceed to Task Breakdown**: Run `/speckit.tasks` to generate implementation tasks

3. **Begin Implementation**:
   - Start with Phase 1 (Authentication) per quickstart guide
   - Follow TDD approach: tests before implementation
   - Iterate through user stories by priority (P1 → P2 → P3 → P4)

---

**Planning Status**: ✅ **COMPLETE** - Ready for task generation and implementation.

**Branch**: `001-sauna-controller-app`  
**Spec**: [spec.md](spec.md)  
**Plan**: plan.md (this file)  
**Research**: [research.md](research.md)  
**Data Model**: [data-model.md](data-model.md)  
**API Contracts**: [contracts/api-contracts.md](contracts/api-contracts.md)  
**Quickstart**: [quickstart.md](quickstart.md)
