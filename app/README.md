# Harvia Sauna Controller

A cross-platform Flutter application for controlling Harvia smart saunas remotely. Built with offline-first architecture, GraphQL/REST APIs, and comprehensive security features.

![Flutter Version](https://img.shields.io/badge/Flutter-3.16%2B-blue)
![Dart Version](https://img.shields.io/badge/Dart-3.0%2B-blue)
![License](https://img.shields.io/badge/License-Proprietary-red)

## Features

✅ **Authentication**: Secure login with JWT token management and automatic refresh  
✅ **Device Management**: Real-time sauna status monitoring and control  
✅ **Temperature Control**: Precise temperature adjustment (40°C - 110°C)  
✅ **Event History**: View and acknowledge sauna events  
✅ **Offline-First**: Full functionality without network connectivity  
✅ **Cross-Platform**: iOS, Android, and Web support  

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Building](#building)
- [Running](#running)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Prerequisites

### Required Tools

- **Flutter SDK**: 3.16.0 or higher (stable channel)
  ```bash
  flutter --version
  # Expected output: Flutter 3.16.0 or later
  ```

- **Dart SDK**: 3.0.0 or higher (included with Flutter)

- **IDE** (choose one):
  - [Visual Studio Code](https://code.visualstudio.com/) with [Flutter extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
  - [Android Studio](https://developer.android.com/studio) with Flutter plugin
  - [IntelliJ IDEA](https://www.jetbrains.com/idea/) with Flutter plugin

### Platform-Specific Requirements

#### iOS Development (macOS only)
- **macOS**: 12.0 (Monterey) or higher
- **Xcode**: 15.0 or higher
- **CocoaPods**: Latest version
  ```bash
  sudo gem install cocoapods
  ```

#### Android Development
- **Android Studio**: Arctic Fox or higher
- **Android SDK**: API Level 26 (Android 8.0) or higher
- **Java Development Kit**: JDK 11 or higher

#### Web Development
- **Chrome**: Latest stable version (for debugging)

### System Requirements

- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 10GB free space
- **Internet**: Required for initial setup and API access

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/harvia/sauna-controller.git
cd sauna-controller/app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Generate Code (Freezed, JSON, Riverpod)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Generate Hive Adapters

```bash
flutter packages pub run build_runner build
```

## Configuration

### Environment Setup

Create `.env` file in the `app/` directory:

```env
# API Configuration
API_BASE_URL=https://prod.api.harvia.io
GRAPHQL_ENDPOINT=https://prod.api.harvia.io/graphql
WS_ENDPOINT=wss://prod.api.harvia.io/graphql

# Feature Flags
ENABLE_ANALYTICS=false
ENABLE_CRASHLYTICS=false
DEBUG_MODE=false
```

### API Keys

⚠️ **Never commit API keys to version control!**

Add your API credentials to `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://prod.api.harvia.io',
  );
  
  // Other constants...
}
```

### Platform-Specific Configuration

#### iOS

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Update **Bundle Identifier**: `com.harvia.saunaController`
4. Set **Minimum Deployment Target**: iOS 13.0
5. Configure signing in **Signing & Capabilities**

#### Android

1. Update `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       applicationId "com.harvia.sauna_controller"
       minSdkVersion 26
       targetSdkVersion 34
       versionCode 1
       versionName "1.0.0"
   }
   ```

2. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

#### Web

Update `web/index.html` with your app metadata:

```html
<head>
  <meta charset="UTF-8">
  <title>Harvia Sauna Controller</title>
  <meta name="description" content="Control your Harvia sauna remotely">
</head>
```

## Building

### Debug Builds

#### iOS
```bash
cd app
flutter build ios --debug
```

#### Android
```bash
cd app
flutter build apk --debug
# or for App Bundle:
flutter build appbundle --debug
```

#### Web
```bash
cd app
flutter build web --debug
```

### Release Builds

#### iOS (requires Apple Developer account)
```bash
cd app
flutter build ios --release
# Then use Xcode to archive and upload to App Store
```

#### Android
```bash
cd app
# Generate keystore (first time only)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

#### Web
```bash
cd app
flutter build web --release --web-renderer canvaskit
# Output: build/web/
```

## Running

### Development Mode

#### iOS Simulator
```bash
cd app
open -a Simulator
flutter run
```

#### Android Emulator
```bash
cd app
# Start emulator from Android Studio, or:
flutter emulators --launch <emulator_id>
flutter run
```

#### Web (Chrome)
```bash
cd app
flutter run -d chrome --web-port=8080
```

### Production Mode

#### iOS Device
```bash
cd app
flutter run --release -d <device-id>
```

#### Android Device
```bash
cd app
flutter run --release -d <device-id>
```

## Testing

### Run All Tests

```bash
cd app
flutter test
```

### Run Specific Test File

```bash
cd app
flutter test test/features/auth/domain/entities/api_session_test.dart
```

### Run Integration Tests

```bash
cd app
flutter test integration_test/
```

### Test Coverage

```bash
cd app
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Widget Tests

```bash
cd app
# Run all widget tests
flutter test test/features/*/presentation/widgets/

# Run specific widget test
flutter test test/features/dashboard/presentation/widgets/device_card_test.dart
```

## Project Structure

```
app/
├── lib/
│   ├── core/                      # Core utilities and constants
│   │   ├── constants/             # API endpoints, app constants
│   │   ├── router/                # Navigation and routing
│   │   ├── theme/                 # App theme and styling
│   │   └── utils/                 # Logger, security, lazy loading
│   ├── features/                  # Feature modules
│   │   ├── auth/                  # Authentication
│   │   │   ├── data/              # Data sources, repositories
│   │   │   ├── domain/            # Entities, use cases
│   │   │   └── presentation/      # UI screens and widgets
│   │   ├── control/               # Device control
│   │   ├── dashboard/             # Dashboard and device list
│   │   ├── events/                # Event history
│   │   └── temperature/           # Temperature control
│   ├── services/                  # Global services
│   │   ├── api/                   # API clients (GraphQL, REST)
│   │   ├── notification/          # Push notifications
│   │   └── sync/                  # Offline sync
│   ├── shared/                    # Shared widgets and providers
│   └── main.dart                  # App entry point
├── test/                          # Unit and widget tests
├── integration_test/              # Integration tests
├── assets/                        # Images, fonts, etc.
├── docs/                          # Documentation
└── pubspec.yaml                   # Dependencies

specs/                             # Feature specifications
└── 001-sauna-controller-app/
    ├── plan.md                    # Technical architecture
    ├── tasks.md                   # Implementation tasks
    ├── data-model.md              # Data models
    ├── contracts/                 # API contracts
    └── quickstart.md              # Developer setup guide
```

## Architecture

### Design Patterns

- **Clean Architecture**: Separation of concerns (data, domain, presentation layers)
- **Repository Pattern**: Abstract data sources
- **Provider Pattern**: State management with Riverpod
- **Offline-First**: Local storage with Hive, sync when online

### State Management

Using **Riverpod 2.4+** with code generation:

```dart
@riverpod
class DeviceListNotifier extends _$DeviceListNotifier {
  @override
  Future<List<Device>> build() async {
    // Initialize state
  }
  
  // Methods to update state
}
```

### Data Flow

```
UI (Widgets)
    ↓ (watch/read providers)
StateNotifiers (Riverpod)
    ↓ (call methods)
Repositories (abstraction)
    ↓ (choose source)
Data Sources (Remote/Local)
    ↓
API / Hive Storage
```

### Offline-First Strategy

1. **Write**: Save to local storage first, queue for sync
2. **Read**: Fetch from local storage, background sync from API
3. **Conflict Resolution**: Last-write-wins with timestamp comparison
4. **Connectivity**: Monitor network status with `connectivity_plus`

## Security

### Authentication

- **JWT Tokens**: Using `idToken` for API authorization
- **Secure Storage**: Tokens encrypted with `flutter_secure_storage`
- **Auto Refresh**: Tokens refreshed 5 minutes before expiry
- **Token Validation**: Format and expiry checked on every request

### Input Validation

All user inputs validated with `InputValidator`:

```dart
InputValidator.validateEmail(email);
InputValidator.validatePassword(password);
InputValidator.validateTemperature(temperature);
```

### Output Sanitization

User-generated content sanitized to prevent XSS:

```dart
DisplayDataSanitizer.sanitizeText(userInput);
DisplayDataSanitizer.sanitizeUserContent(userNote);
```

### Rate Limiting

- **Default**: 60 requests per minute
- **Exponential Backoff**: 1s → 2s → 4s → 8s → 16s → 32s
- **Per-Endpoint Tracking**: Separate limits for different routes

See [SECURITY.md](docs/SECURITY.md) for complete security documentation.

## Troubleshooting

### Build Errors

#### Error: "CocoaPods not installed"
```bash
sudo gem install cocoapods
cd ios && pod install
```

#### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### Error: "Build runner conflicts"
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Runtime Errors

#### Error: "HiveError: Box not found"
```dart
// Ensure Hive is initialized in main.dart
await Hive.initFlutter();
await Hive.openBox('sessions');
```

#### Error: "GraphQL: Network error"
- Check API endpoint in `ApiConstants.graphqlEndpoint`
- Verify network connectivity
- Ensure API server is running

#### Error: "Token expired"
- Token auto-refresh should handle this
- If persists, logout and login again
- Check token expiry logic in `AuthInterceptor`

### Common Issues

**Q: Flutter doctor shows issues with Android licenses**
```bash
flutter doctor --android-licenses
# Accept all licenses
```

**Q: iOS build fails with "No profiles for 'com.harvia.saunaController'"**
- Open `ios/Runner.xcworkspace` in Xcode
- Select your development team in Signing & Capabilities
- Change bundle identifier if needed

**Q: Web build shows CORS errors**
- CORS is configured server-side
- For development, use Flutter's proxy: `--web-port=8080`
- In production, ensure backend allows your domain

## Contributing

### Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` before committing
- Format code with `flutter format .`

### Commit Guidelines

```
feat: Add temperature scheduling feature
fix: Resolve token refresh race condition
docs: Update README with testing instructions
test: Add widget tests for DeviceCard
refactor: Simplify offline sync logic
```

### Pull Request Process

1. Create feature branch: `git checkout -b feature/temperature-scheduling`
2. Make changes with tests
3. Run `flutter analyze` and `flutter test`
4. Push and create PR with description
5. Wait for code review and CI checks

## License

Copyright © 2024 Harvia Ltd. All rights reserved.

This software is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

---

## Support

- **Documentation**: [docs/](docs/)
- **API Docs**: See [API_INTEGRATION.md](docs/API_INTEGRATION.md)
- **Issues**: Report bugs via GitHub Issues
- **Email**: support@harvia.com

## Changelog

### v1.0.0 (2024-12-20)
- ✅ Initial release
- ✅ Authentication with JWT
- ✅ Device status monitoring
- ✅ Temperature control
- ✅ Event history
- ✅ Offline-first architecture
- ✅ Cross-platform support (iOS, Android, Web)

---

**Built with ❤️ using Flutter**
