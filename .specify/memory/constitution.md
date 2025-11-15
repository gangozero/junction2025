# Harvia Sauna Controller App Constitution

## Core Principles

### I. Test-First Development (NON-NEGOTIABLE)

All features MUST have widget tests before UI implementation.

**Requirements**:
- Widget tests MUST be written before implementing presentation layer components
- Each screen/widget MUST have corresponding test file in `test/widget/`
- Test coverage MUST verify UI state changes, user interactions, and error states
- Integration tests MUST validate end-to-end user story flows

**Rationale**: Ensures UI components are testable by design, prevents regressions, and validates user story acceptance criteria before deployment.

### II. Offline-First Architecture (NON-NEGOTIABLE)

All data operations MUST implement cache-first strategy.

**Requirements**:
- All repositories MUST implement cache-first data access pattern (check local cache before network)
- Network failures MUST NOT prevent app functionality for cached data
- User actions MUST queue for background sync when offline
- Cache invalidation strategy MUST be explicit for each data type
- GraphQL queries MUST use `FetchPolicy.cacheFirst` or `FetchPolicy.networkFirst` with cache fallback

**Rationale**: Sauna control requires reliable operation regardless of network conditions. Users must view cached status and queue commands even when connectivity is poor.

### III. Platform Parity (NON-NEGOTIABLE)

All user stories MUST deliver identical functionality on iOS, Android, and Web.

**Requirements**:
- Each user story implementation MUST work on all three platforms
- Platform-specific code MUST be abstracted behind common interfaces
- UI/UX differences MUST be limited to platform conventions (Material vs Cupertino, responsive layouts)
- Feature flags for platform limitations MUST be explicitly documented and justified
- Integration tests MUST run on all platforms

**Rationale**: Users expect consistent sauna control experience regardless of device. Feature fragmentation degrades user trust and increases support burden.

### IV. Security by Default (NON-NEGOTIABLE)

All API tokens MUST use platform-native secure storage (no plaintext).

**Requirements**:
- Authentication tokens MUST NEVER be stored in plaintext
- Mobile platforms MUST use `flutter_secure_storage` (iOS Keychain, Android Keystore)
- Web platform MUST use encrypted IndexedDB with session-derived encryption keys
- Encryption keys MUST be cleared on logout
- Token refresh MUST happen automatically via interceptors (no manual token handling in UI)
- All API requests MUST validate token expiry before transmission

**Rationale**: Sauna control API access grants physical device control. Compromised tokens could enable unauthorized sauna operation, creating safety and privacy risks.

### V. Real-Time First (NON-NEGOTIABLE)

Status updates MUST use GraphQL subscriptions (polling only as fallback).

**Requirements**:
- Device state changes MUST use GraphQL subscriptions over WebSocket
- Subscription reconnection MUST implement exponential backoff (1s, 2s, 4s, 8s, 16s, 32s, max 60s)
- Polling MUST only be used when WebSocket is unavailable (browser incompatibility, corporate firewall)
- Status updates MUST render within 2 seconds of server event
- Subscription lifecycle MUST be managed via app lifecycle (pause on background, resume on foreground)

**Rationale**: Real-time temperature and state updates are core value proposition. Polling introduces unnecessary latency and server load. Users expect instant feedback when sauna state changes.

## Quality Gates

### Pre-Implementation Checklist

Before starting any user story implementation, verify:
- [ ] Widget test file created for all new screens/widgets
- [ ] Repository interface defines cache-first methods
- [ ] Platform abstraction interfaces defined for platform-specific features
- [ ] Secure storage integration verified for any credential handling
- [ ] GraphQL subscription schema reviewed for real-time data

### Pre-Merge Checklist

Before merging any user story branch:
- [ ] All widget tests passing on iOS, Android, and Web
- [ ] Offline mode tested (airplane mode, network disconnection)
- [ ] Platform parity verified across all three platforms
- [ ] No plaintext credentials in code, logs, or storage
- [ ] GraphQL subscriptions tested with network interruptions
- [ ] Manual QA performed on at least two platforms

## Governance

**Constitution Authority**: This constitution is NON-NEGOTIABLE and supersedes all other development practices, guidelines, and preferences for this project.

**Compliance Verification**:
- All pull requests MUST pass automated checks for:
  - Test coverage (widget tests present for UI changes)
  - Secure storage usage (no plaintext token storage)
  - Platform compatibility (builds succeed on iOS/Android/Web)
- Code reviews MUST verify adherence to all five core principles
- Constitution violations MUST be rejected at PR review stage

**Amendment Process**:
- Amendments require documentation of:
  1. Specific principle being amended
  2. Justification for change (technical limitation, user feedback, security concern)
  3. Migration plan for existing code
- Amendments MUST be approved before implementation work begins
- Amendment history MUST be tracked in this file

**Enforcement**:
- `/speckit.analyze` command MUST validate compliance with these principles
- Any constitution violation discovered MUST be treated as CRITICAL priority
- Technical debt that violates constitution MUST be resolved before new features

---

**Version**: 1.0.0  
**Ratified**: 2025-11-15  
**Last Amended**: 2025-11-15  
**Project**: Harvia Sauna Controller App (001-sauna-controller-app)  
**Status**: Active
