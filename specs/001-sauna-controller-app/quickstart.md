# Quickstart Guide: Sauna Controller Mobile Application

**Feature**: Sauna Controller Mobile Application  
**Date**: 2025-11-15  
**Target Audience**: Developers implementing this feature

This guide provides step-by-step instructions to set up the development environment and begin implementation.

---

## Prerequisites

### Required Tools

- **Flutter SDK**: 3.16.0 or higher (stable channel)
  ```bash
  flutter --version
  # Should show: Flutter 3.16.0 or later
  ```

- **Dart SDK**: 3.0.0 or higher (included with Flutter)

- **IDE**: One of the following:
  - VS Code with Flutter/Dart extensions
  - Android Studio with Flutter plugin
  - IntelliJ IDEA with Flutter plugin

- **Platform SDKs**:
  - **iOS**: Xcode 15.0+ (macOS only) for iOS development
  - **Android**: Android Studio with SDK Platform 26+ (API Level 26, Android 8.0)

### Account Requirements

- **Harvia Developer Account**: Access to Harvia API
  - Email: [developer email]
  - API Endpoint: https://prod.api.harvia.io
  - Test credentials for development

### System Requirements

- **macOS**: 12.0+ (for iOS development)
- **Windows**: 10+ (for Android only)
- **Linux**: Ubuntu 18.04+ (for Android only)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 10GB free space

---

## Project Setup

### 1. Initialize Flutter Project

```bash
# Navigate to repository root
cd /Users/andreyprokopiev/workspace/home-projects/geoapp/harvia-msga

# Create Flutter project (if not already created)
flutter create --org com.harvia --project-name sauna_controller .

# Verify creation
flutter doctor
```

### 2. Configure `pubspec.yaml`

Add dependencies to `pubspec.yaml`:

```yaml
name: sauna_controller
description: Harvia Sauna Controller Mobile Application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # GraphQL Client
  graphql_flutter: ^5.1.0
  
  # HTTP Client
  dio: ^5.4.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Secure Storage
  flutter_secure_storage: ^9.0.0
  
  # Notifications
  flutter_local_notifications: ^16.0.0
  
  # Background Tasks
  workmanager: ^0.5.0
  
  # JSON Serialization
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  
  # Utilities
  intl: ^0.18.0
  uuid: ^4.0.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  hive_generator: ^2.0.0
  riverpod_generator: ^2.3.0
  
  # Testing
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
  
  # Linting
  flutter_lints: ^3.0.0
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Platform-Specific Settings

#### iOS Configuration

Edit `ios/Runner/Info.plist`:

```xml
<dict>
  <!-- Existing keys... -->
  
  <!-- Background modes for scheduling -->
  <key>UIBackgroundModes</key>
  <array>
    <string>fetch</string>
    <string>processing</string>
  </array>
  
  <!-- Notification permissions -->
  <key>NSUserNotificationUsageDescription</key>
  <string>Receive alerts about sauna events and scheduled activations</string>
  
  <!-- Network usage -->
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
  </dict>
</dict>
```

Set minimum iOS version in `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

#### Android Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 26  // Android 8.0
        targetSdkVersion 34
        // ... other configs
    }
}
```

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    
    <application>
        <!-- ... existing config ... -->
        
        <!-- Background task service -->
        <service
            android:name="be.tramckrijte.workmanager.WorkmanagerPlugin"
            android:exported="false"
            android:enabled="true"/>
    </application>
</manifest>
```

---

## Project Structure Setup

### 1. Create Directory Structure

```bash
# Create feature directories
mkdir -p lib/core/{constants,theme,utils,error}
mkdir -p lib/features/{auth,dashboard,device,control,schedule,events}/{data,domain,presentation}
mkdir -p lib/services/{api/{graphql,rest,websocket},storage,notifications,background}
mkdir -p lib/shared/{widgets,models}
mkdir -p test/{unit,widget,integration}
```

### 2. Initialize Core Files

Create `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // TODO: Register Hive adapters
  
  runApp(
    const ProviderScope(
      child: SaunaControllerApp(),
    ),
  );
}

class SaunaControllerApp extends StatelessWidget {
  const SaunaControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sauna Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const Placeholder(), // TODO: Add auth/splash screen
    );
  }
}
```

Create `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String endpointConfigUrl = 'https://prod.api.harvia.io/endpoints';
  
  // Token expiry buffer (refresh 5 minutes before expiry)
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  
  // Subscription reconnection settings
  static const Duration initialReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);
  
  // Cache settings
  static const int maxEventsCached = 1000;
  static const Duration eventRetentionPeriod = Duration(days: 30);
}
```

---

## Development Workflow

### Phase 1: Setup Foundation (Week 1)

**Goal**: Core infrastructure and authentication

1. **Day 1-2**: API Service Layer
   ```bash
   # Implement files
   lib/services/api/rest/auth_client.dart
   lib/services/api/graphql/graphql_client.dart
   lib/services/storage/secure_storage_service.dart
   ```
   
   **Tasks**:
   - Fetch endpoint configuration
   - Implement REST authentication client
   - Setup secure token storage
   - Create APISession model

2. **Day 3-4**: Authentication Feature
   ```bash
   # Implement files
   lib/features/auth/data/auth_repository.dart
   lib/features/auth/domain/auth_state.dart
   lib/features/auth/presentation/login_screen.dart
   ```
   
   **Tasks**:
   - Login screen UI
   - Token management logic
   - Auto-refresh mechanism
   - Logout functionality

3. **Day 5**: Testing
   ```bash
   # Create tests
   test/unit/services/api/rest/auth_client_test.dart
   test/widget/features/auth/login_screen_test.dart
   ```
   
   **Run tests**:
   ```bash
   flutter test
   ```

### Phase 2: Device Management (Week 2)

**Goal**: Device listing and basic monitoring

1. **Day 1-2**: GraphQL Integration
   ```bash
   # Implement files
   lib/services/api/graphql/device_service.dart
   lib/features/device/data/device_repository.dart
   ```
   
   **Tasks**:
   - GraphQL query implementation
   - Device list fetching
   - Local caching with Hive
   - Device model creation

2. **Day 3-4**: Dashboard Screen
   ```bash
   # Implement files
   lib/features/dashboard/presentation/dashboard_screen.dart
   lib/shared/widgets/device_card.dart
   ```
   
   **Tasks**:
   - Device list UI
   - Status display (temperature, power)
   - Device selection logic
   - Pull-to-refresh

3. **Day 5**: Real-time Subscriptions
   ```bash
   # Implement files
   lib/services/api/websocket/subscription_manager.dart
   ```
   
   **Tasks**:
   - WebSocket connection setup
   - Subscribe to device state changes
   - Auto-reconnection logic
   - Update UI on subscription data

### Phase 3: Control Features (Week 3)

**Goal**: Power and temperature control

1. **Day 1-2**: Command Implementation
   ```bash
   # Implement files
   lib/features/control/data/control_repository.dart
   lib/features/control/domain/command_request.dart
   ```
   
   **Tasks**:
   - GraphQL mutations for commands
   - Command validation logic
   - Error handling
   - Confirmation feedback

2. **Day 3-4**: Control UI
   ```bash
   # Implement files
   lib/features/control/presentation/control_panel.dart
   lib/shared/widgets/temperature_slider.dart
   ```
   
   **Tasks**:
   - Power on/off buttons
   - Temperature adjustment slider
   - Visual feedback (loading, success, error)
   - Debounce temperature changes

3. **Day 5**: Offline Support
   ```bash
   # Implement files
   lib/core/utils/connectivity_checker.dart
   ```
   
   **Tasks**:
   - Detect network status
   - Queue commands when offline
   - Retry logic on reconnection
   - Offline banner UI

### Phase 4: Scheduling & Events (Week 4)

**Goal**: Local scheduling and event notifications

1. **Day 1-2**: Schedule Management
   ```bash
   # Implement files
   lib/features/schedule/data/schedule_repository.dart
   lib/features/schedule/presentation/schedule_screen.dart
   ```
   
   **Tasks**:
   - Hive storage for schedules
   - CRUD operations
   - Schedule list UI
   - Background task setup with workmanager

2. **Day 3-4**: Event System
   ```bash
   # Implement files
   lib/features/events/data/event_repository.dart
   lib/features/events/presentation/events_screen.dart
   lib/services/notifications/notification_service.dart
   ```
   
   **Tasks**:
   - Subscribe to Events Service
   - Local event storage (Hive)
   - Event filtering UI
   - Push notifications for critical events

3. **Day 5**: Integration Testing
   ```bash
   test/integration/app_test.dart
   ```
   
   **Run integration tests**:
   ```bash
   flutter test integration_test/
   ```

---

## Running the Application

### Development Mode

```bash
# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run with hot reload
flutter run --debug

# Run with verbose logging
flutter run --verbose
```

### Testing

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/unit/services/api/rest/auth_client_test.dart

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Run widget tests
flutter test test/widget/

# Run integration tests
flutter test integration_test/
```

### Code Generation

```bash
# Generate code for Riverpod, Freezed, JSON serialization, Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate on file changes)
flutter pub run build_runner watch
```

---

## Environment Configuration

### Development Environment

Create `.env.dev`:
```
API_BASE_URL=https://prod.api.harvia.io
ENABLE_LOGGING=true
LOG_LEVEL=debug
```

### Production Environment

Create `.env.prod`:
```
API_BASE_URL=https://prod.api.harvia.io
ENABLE_LOGGING=false
LOG_LEVEL=error
```

**Note**: Use `flutter_dotenv` package to load environment variables if needed.

---

## Debugging Tips

### Common Issues

1. **GraphQL Connection Fails**
   - Verify token is not expired
   - Check endpoint configuration URL
   - Validate Authorization header format

2. **WebSocket Disconnects**
   - Implement reconnection with exponential backoff
   - Check network connectivity
   - Monitor subscription lifecycle logs

3. **Background Tasks Not Running**
   - Verify platform-specific permissions
   - Check workmanager registration
   - Test on physical device (simulators have limitations)

4. **Hive Storage Errors**
   - Ensure adapters are registered before opening boxes
   - Use type adapters for custom models
   - Check box names are unique

### Logging

Add logging throughout the app:

```dart
import 'dart:developer' as developer;

void logInfo(String message) {
  developer.log(message, name: 'SaunaController', level: 800);
}

void logError(String message, [Object? error, StackTrace? stackTrace]) {
  developer.log(
    message,
    name: 'SaunaController',
    error: error,
    stackTrace: stackTrace,
    level: 1000,
  );
}
```

---

## Next Steps

1. **Review Specification**: Read [spec.md](../spec.md) for detailed requirements
2. **Review Data Model**: Study [data-model.md](data-model.md) for entity definitions
3. **Review API Contracts**: Understand [contracts/api-contracts.md](contracts/api-contracts.md)
4. **Start Implementation**: Begin with Phase 1 (Authentication)
5. **Write Tests**: Follow TDD approach - write tests before implementation
6. **Iterate**: Build incrementally, test continuously

---

## Resources

- **Flutter Documentation**: https://docs.flutter.dev
- **Riverpod Documentation**: https://riverpod.dev
- **GraphQL Flutter**: https://github.com/zino-app/graphql-flutter
- **Hive Documentation**: https://docs.hivedb.dev
- **Harvia API Docs**: https://harvia.io/api

---

**Ready to Code!** Follow the development workflow above and refer to the detailed planning documents as needed.
