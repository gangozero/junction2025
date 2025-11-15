# Setup Validation Checklist

This document provides a comprehensive checklist to validate the development environment setup instructions from the [README.md](../README.md) and [quickstart.md](../../specs/001-sauna-controller-app/quickstart.md).

## Purpose

Ensure that a new developer can successfully:
1. Set up the development environment from scratch
2. Build and run the application on all platforms
3. Execute tests successfully
4. Follow all documentation without errors

## Pre-Validation Setup

**Test Environment**:
- [ ] Use a clean machine or VM (macOS for iOS, Windows/Linux for Android only)
- [ ] Do NOT use an existing Flutter development environment
- [ ] Fresh OS install or Docker container recommended
- [ ] Document OS version and hardware specs

**Required for Full Validation**:
- [ ] macOS 12+ (for iOS testing)
- [ ] Android device or emulator
- [ ] iOS device or simulator (macOS only)
- [ ] Stable internet connection

## Phase 1: Prerequisites Validation

### 1.1 Flutter SDK Installation

- [ ] Follow Flutter installation guide for your OS
- [ ] Run `flutter --version`
- [ ] Verify Flutter version is 3.16.0 or higher
- [ ] Run `flutter doctor`
- [ ] All required components show ✓ (green checkmarks)

**Expected Output**:
```
Flutter 3.16.0 • channel stable • https://github.com/flutter/flutter.git
Tools • Dart 3.x.x • DevTools 2.x.x
```

**Issues Encountered**:
```
[Document any issues here]
```

### 1.2 Dart SDK Verification

- [ ] Run `dart --version`
- [ ] Verify Dart version is 3.0.0 or higher

**Expected Output**:
```
Dart SDK version: 3.x.x (stable)
```

### 1.3 IDE Setup

Choose one:

**VS Code**:
- [ ] Install VS Code
- [ ] Install Flutter extension
- [ ] Install Dart extension
- [ ] Run `Flutter: Run Flutter Doctor` from command palette
- [ ] No errors reported

**Android Studio**:
- [ ] Install Android Studio
- [ ] Install Flutter plugin
- [ ] Install Dart plugin
- [ ] Configure Flutter SDK path
- [ ] Restart Android Studio

**IntelliJ IDEA**:
- [ ] Install IntelliJ IDEA
- [ ] Install Flutter plugin
- [ ] Install Dart plugin
- [ ] Configure Flutter SDK path
- [ ] Restart IntelliJ

**Issues Encountered**:
```
[Document any issues here]
```

### 1.4 iOS Setup (macOS Only)

- [ ] macOS version is 12.0 (Monterey) or higher
- [ ] Install Xcode 15.0 or higher from App Store
- [ ] Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- [ ] Run `sudo xcodebuild -runFirstLaunch`
- [ ] Accept Xcode license: `sudo xcodebuild -license accept`
- [ ] Install CocoaPods: `sudo gem install cocoapods`
- [ ] Verify: `pod --version`
- [ ] Open iOS Simulator: `open -a Simulator`

**Expected Output**:
```
pod version 1.x.x or higher
```

**Issues Encountered**:
```
[Document any issues here]
```

### 1.5 Android Setup

- [ ] Install Android Studio (if not already done)
- [ ] Open Android Studio
- [ ] Install Android SDK Platform 26 (API Level 26, Android 8.0) or higher
- [ ] Install Android SDK Build-Tools
- [ ] Install Android Emulator
- [ ] Create AVD (Android Virtual Device): Pixel 4, API 33+
- [ ] Accept Android licenses: `flutter doctor --android-licenses`
- [ ] Verify: `flutter doctor` shows Android toolchain ✓

**Issues Encountered**:
```
[Document any issues here]
```

### 1.6 Web Setup

- [ ] Install Chrome browser
- [ ] Verify: `flutter devices` shows `chrome` as an option

**Expected Output**:
```
Chrome (web) • chrome • web-javascript • Google Chrome 120.x.x
```

## Phase 2: Project Setup Validation

### 2.1 Clone Repository

- [ ] Run `git clone https://github.com/harvia/sauna-controller.git`
- [ ] Navigate to project: `cd sauna-controller/app`
- [ ] Verify directory structure exists (lib/, test/, pubspec.yaml)

**Issues Encountered**:
```
[Document any issues here]
```

### 2.2 Install Dependencies

- [ ] Run `flutter pub get`
- [ ] No errors during dependency resolution
- [ ] All packages downloaded successfully

**Expected Output**:
```
Running "flutter pub get" in app...
Resolving dependencies...
Got dependencies!
```

**Issues Encountered**:
```
[Document any issues here]
```

### 2.3 Code Generation

- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No errors during code generation
- [ ] Generated files appear in lib/ (*.g.dart, *.freezed.dart)

**Expected Output**:
```
[INFO] Succeeded after X.Xs with Y outputs
```

**Issues Encountered**:
```
[Document any issues here]
```

### 2.4 Environment Configuration

- [ ] Create `.env` file in app/ directory (if required)
- [ ] Add API_BASE_URL=https://prod.api.harvia.io
- [ ] Add GRAPHQL_ENDPOINT=https://prod.api.harvia.io/graphql
- [ ] Verify file is NOT committed to git (.gitignore)

**Issues Encountered**:
```
[Document any issues here]
```

## Phase 3: Platform Configuration Validation

### 3.1 iOS Configuration

- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select Runner target
- [ ] Bundle Identifier is set: `com.harvia.saunaController`
- [ ] Deployment Target is iOS 13.0 or higher
- [ ] Open `ios/Podfile`
- [ ] Verify platform version: `platform :ios, '13.0'`
- [ ] Run `cd ios && pod install && cd ..`
- [ ] No errors during pod installation

**Expected Output**:
```
Pod installation complete! X pods installed.
```

**Issues Encountered**:
```
[Document any issues here]
```

### 3.2 Android Configuration

- [ ] Open `android/app/build.gradle`
- [ ] minSdkVersion is 26
- [ ] targetSdkVersion is 34
- [ ] applicationId is `com.harvia.sauna_controller`
- [ ] Open `android/app/src/main/AndroidManifest.xml`
- [ ] INTERNET permission is present
- [ ] POST_NOTIFICATIONS permission is present (if needed)

**Issues Encountered**:
```
[Document any issues here]
```

### 3.3 Web Configuration

- [ ] Open `web/index.html`
- [ ] Title is set: "Harvia Sauna Controller"
- [ ] Meta description is present
- [ ] Favicon link is present

**Issues Encountered**:
```
[Document any issues here]
```

## Phase 4: Build Validation

### 4.1 Analyze Code

- [ ] Run `flutter analyze`
- [ ] Zero errors
- [ ] Document warnings (if any)

**Expected Output**:
```
Analyzing app...
No issues found!
```

**Issues Encountered**:
```
[Document any issues here]
```

### 4.2 Run Tests

- [ ] Run `flutter test`
- [ ] All tests pass
- [ ] No test failures

**Expected Output**:
```
All tests passed!
```

**Test Results**:
```
Total tests: X
Passed: X
Failed: 0
```

**Issues Encountered**:
```
[Document any issues here]
```

### 4.3 iOS Debug Build

- [ ] Connect iOS device or start simulator
- [ ] Run `flutter run -d <device-id>`
- [ ] App builds successfully
- [ ] App launches on device/simulator
- [ ] No runtime errors

**Build Time**: _____ seconds

**Issues Encountered**:
```
[Document any issues here]
```

### 4.4 Android Debug Build

- [ ] Start Android emulator or connect device
- [ ] Run `flutter run -d <device-id>`
- [ ] App builds successfully
- [ ] App launches on device/emulator
- [ ] No runtime errors

**Build Time**: _____ seconds

**Issues Encountered**:
```
[Document any issues here]
```

### 4.5 Web Debug Build

- [ ] Run `flutter run -d chrome`
- [ ] App builds successfully
- [ ] App launches in Chrome
- [ ] No runtime errors in console

**Build Time**: _____ seconds

**Issues Encountered**:
```
[Document any issues here]
```

## Phase 5: Release Build Validation

### 5.1 iOS Release Build

- [ ] Run `flutter build ios --release --no-codesign`
- [ ] Build completes successfully
- [ ] No errors

**Build Time**: _____ seconds

**Issues Encountered**:
```
[Document any issues here]
```

### 5.2 Android Release APK

- [ ] Run `flutter build apk --release`
- [ ] Build completes successfully
- [ ] APK created at `build/app/outputs/flutter-apk/app-release.apk`
- [ ] APK size is reasonable (< 50MB)

**Build Time**: _____ seconds
**APK Size**: _____ MB

**Issues Encountered**:
```
[Document any issues here]
```

### 5.3 Android App Bundle

- [ ] Run `flutter build appbundle --release`
- [ ] Build completes successfully
- [ ] AAB created at `build/app/outputs/bundle/release/app-release.aab`

**Build Time**: _____ seconds
**AAB Size**: _____ MB

**Issues Encountered**:
```
[Document any issues here]
```

### 5.4 Web Release Build

- [ ] Run `flutter build web --release --web-renderer canvaskit`
- [ ] Build completes successfully
- [ ] Output directory `build/web/` contains index.html, main.dart.js

**Build Time**: _____ seconds
**Build Size**: _____ MB

**Issues Encountered**:
```
[Document any issues here]
```

## Phase 6: Functional Testing

### 6.1 Basic UI Navigation

- [ ] App launches to login screen
- [ ] Can navigate between screens
- [ ] UI renders correctly
- [ ] No visual glitches

**Issues Encountered**:
```
[Document any issues here]
```

### 6.2 Hot Reload (Debug Mode)

- [ ] Make a small UI change (change text color)
- [ ] Press `r` in terminal for hot reload
- [ ] Change appears immediately
- [ ] No errors

**Issues Encountered**:
```
[Document any issues here]
```

### 6.3 Hot Restart (Debug Mode)

- [ ] Press `R` in terminal for hot restart
- [ ] App restarts successfully
- [ ] State is reset
- [ ] No errors

**Issues Encountered**:
```
[Document any issues here]
```

## Phase 7: Documentation Validation

### 7.1 README.md

- [ ] All installation steps work as written
- [ ] All command examples execute correctly
- [ ] No broken links
- [ ] Code examples are accurate
- [ ] Screenshots (if any) match current UI

**Suggestions for Improvement**:
```
[Document any suggestions here]
```

### 7.2 API_INTEGRATION.md

- [ ] Code examples are syntactically correct
- [ ] Import statements are accurate
- [ ] API endpoints match actual implementation

**Suggestions for Improvement**:
```
[Document any suggestions here]
```

### 7.3 SECURITY.md

- [ ] Security practices are implemented in code
- [ ] Examples match actual code structure

**Suggestions for Improvement**:
```
[Document any suggestions here]
```

### 7.4 RELEASE_BUILD.md

- [ ] Release build steps work as documented
- [ ] Configuration examples are accurate

**Suggestions for Improvement**:
```
[Document any suggestions here]
```

## Phase 8: Final Validation

### 8.1 Clean Build Test

- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Run `flutter run` on each platform
- [ ] All platforms work without errors

**Issues Encountered**:
```
[Document any issues here]
```

### 8.2 Performance Check

- [ ] App launches in < 5 seconds
- [ ] UI is responsive (no lag)
- [ ] Animations are smooth (60 FPS)

**Performance Notes**:
```
Launch time: _____ seconds
Frame rate: _____ FPS average
```

## Validation Summary

**Validation Date**: _______________  
**Validated By**: _______________  
**OS**: _______________  
**Flutter Version**: _______________  

**Overall Result**: ☐ PASS  ☐ FAIL

**Critical Issues Found**: _____

**Minor Issues Found**: _____

**Documentation Updates Needed**:
```
[List any documentation updates needed based on validation]
```

**Recommended Actions**:
```
[List recommended next steps]
```

---

## Notes for Continuous Validation

- **Frequency**: Validate setup on each major release
- **Environments**: Test on macOS, Windows, Linux (if supporting)
- **Automation**: Consider automating parts of this validation with CI/CD
- **Feedback Loop**: Update documentation based on validation results

---

**Last Updated**: 2024-12-20  
**Version**: 1.0  
**Next Review**: [Date of next validation]
