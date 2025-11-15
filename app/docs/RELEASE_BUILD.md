# Release Build Guide

This document provides step-by-step instructions for creating production release builds for all platforms.

## Prerequisites

- All development dependencies installed (see [README.md](../README.md))
- Code signing configured for iOS
- Keystore created for Android
- Production API endpoints configured
- All tests passing

## Pre-Release Checklist

Before creating release builds:

- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Verify API endpoints point to production
- [ ] Test on physical devices (iOS, Android)
- [ ] Test critical user flows end-to-end
- [ ] Review security audit (docs/SECURITY.md)
- [ ] Backup current codebase

## Version Management

### Update Version Number

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        ↑     ↑
#        |     Build number (increment for each release)
#        Version name (semantic versioning)
```

**Semantic Versioning**:
- **Major** (1.x.x): Breaking changes
- **Minor** (x.1.x): New features, backwards compatible
- **Patch** (x.x.1): Bug fixes only

**Build Number**: Increment for every release (iOS CFBundleVersion, Android versionCode)

## iOS Release Build

### 1. Configure Xcode Project

Open `ios/Runner.xcworkspace` in Xcode:

1. **Select Runner target** → General tab
2. **Bundle Identifier**: `com.harvia.saunaController`
3. **Version**: `1.0.0` (from pubspec.yaml)
4. **Build**: `1` (from pubspec.yaml)
5. **Deployment Target**: iOS 13.0 or higher

### 2. Configure Signing

1. **Signing & Capabilities** tab
2. Select your **Team** (Apple Developer account)
3. **Automatically manage signing**: ✓ (recommended)
4. Or manually configure provisioning profiles

### 3. Configure Build Settings

1. **Build Settings** tab → All + Combined
2. Search for **"Bitcode"**
   - **Enable Bitcode**: No (Flutter doesn't support it)
3. Search for **"Optimization Level"**
   - **Release**: -O3 (Fastest, Smallest)

### 4. Build Release IPA

#### Option A: Command Line (recommended)

```bash
cd app

# Clean previous builds
flutter clean
rm -rf ios/Pods
cd ios && pod install && cd ..

# Build release
flutter build ios --release --no-codesign

# Or build with code signing
flutter build ipa --release

# Output: build/ios/ipa/sauna_controller.ipa
```

#### Option B: Xcode Archive

```bash
# Build Flutter framework
flutter build ios --release

# Open Xcode
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Generic iOS Device** (or your connected device)
2. **Product** → **Archive**
3. Wait for archive to complete
4. **Distribute App** → **App Store Connect**
5. Follow upload wizard

### 5. Upload to App Store

#### Using Xcode (GUI)

1. After archiving, click **Distribute App**
2. Select **App Store Connect**
3. Upload
4. Go to [App Store Connect](https://appstoreconnect.apple.com)
5. Add build to release
6. Submit for review

#### Using Transporter (recommended)

1. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784)
2. Drag `sauna_controller.ipa` into Transporter
3. Click **Deliver**
4. Go to App Store Connect to manage release

### 6. iOS Release Checklist

- [ ] Screenshots prepared (all required sizes)
- [ ] App icon configured (1024x1024 PNG)
- [ ] Privacy policy URL provided
- [ ] App description written
- [ ] Keywords optimized
- [ ] Age rating configured
- [ ] In-app purchases configured (if any)
- [ ] Test flight testing completed

## Android Release Build

### 1. Create Keystore (First Time Only)

```bash
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

# Enter keystore password when prompted
# Enter key password when prompted
# Answer identity questions
```

**⚠️ CRITICAL**: Backup `upload-keystore.jks` securely! Loss means you cannot update your app.

### 2. Configure Signing

Create `android/key.properties`:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-keystore>
# Example: storeFile=/Users/username/upload-keystore.jks
```

**⚠️ NEVER commit `key.properties` to version control!**

Add to `android/.gitignore`:

```
key.properties
*.jks
*.keystore
```

### 3. Update build.gradle

Edit `android/app/build.gradle`:

```gradle
// Load keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... other config

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            
            // Shrink and obfuscate code
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 4. Configure ProGuard

Create `android/app/proguard-rules.pro`:

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class * extends com.hivedb.** { *; }
-keep class com.hivedb.** { *; }

# GraphQL
-keep class com.graphql.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
```

### 5. Build Release APK/Bundle

#### APK (for direct distribution)

```bash
cd app
flutter clean
flutter pub get
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (for Play Store - recommended)

```bash
cd app
flutter clean
flutter pub get
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

**Why App Bundle?**
- Smaller download sizes (dynamic delivery)
- Automatic APK generation for each device config
- Required for new apps on Play Store

### 6. Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. **Production** → **Create new release**
4. Upload `app-release.aab`
5. Add release notes
6. Review and roll out

### 7. Android Release Checklist

- [ ] Screenshots prepared (phone, tablet, 7-inch, 10-inch)
- [ ] Feature graphic (1024x500)
- [ ] App icon configured
- [ ] Privacy policy URL provided
- [ ] App description written
- [ ] Content rating completed
- [ ] Target audience selected
- [ ] Play Store listing optimized
- [ ] Internal testing completed

## Web Release Build

### 1. Configure Web Settings

Edit `web/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- SEO -->
  <title>Harvia Sauna Controller</title>
  <meta name="description" content="Control your Harvia sauna remotely from anywhere">
  <meta name="keywords" content="sauna, smart home, harvia, iot">
  
  <!-- Open Graph -->
  <meta property="og:title" content="Harvia Sauna Controller">
  <meta property="og:description" content="Control your Harvia sauna remotely">
  <meta property="og:image" content="icons/Icon-512.png">
  
  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  
  <!-- Manifest -->
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

### 2. Configure manifest.json

Edit `web/manifest.json`:

```json
{
  "name": "Harvia Sauna Controller",
  "short_name": "Sauna Controller",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#FF6B35",
  "description": "Control your Harvia sauna remotely",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

### 3. Build Release Web App

```bash
cd app
flutter clean
flutter pub get

# Build with CanvasKit renderer (best performance)
flutter build web --release --web-renderer canvaskit

# Or use HTML renderer (better compatibility, larger size)
flutter build web --release --web-renderer html

# Output: build/web/
```

**Renderers Comparison**:
- **CanvasKit**: Better performance, larger initial load, uses WebGL
- **HTML**: Better compatibility, smaller size, uses HTML/CSS

### 4. Deploy to Hosting

#### Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting
# Select build/web as public directory
# Configure as single-page app: Yes
# Overwrite index.html: No

# Deploy
firebase deploy --only hosting

# Output: https://your-app.web.app
```

#### Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Deploy
cd build/web
netlify deploy --prod

# Follow prompts
```

#### Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd build/web
vercel --prod
```

#### Custom Server (Nginx)

```nginx
server {
    listen 80;
    server_name sauna.harvia.com;
    
    root /var/www/sauna-controller;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Single-page app routing
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 5. Web Release Checklist

- [ ] HTTPS configured (SSL certificate)
- [ ] Service worker configured (PWA)
- [ ] Icons generated (192x192, 512x512, maskable)
- [ ] Meta tags optimized (SEO)
- [ ] CORS configured on API server
- [ ] Gzip compression enabled
- [ ] Browser caching configured
- [ ] Analytics configured (if using)
- [ ] Error monitoring configured
- [ ] Performance tested (Lighthouse)

## Post-Release

### 1. Monitor Crash Reports

- **iOS**: Xcode Organizer → Crashes
- **Android**: Play Console → Quality → Crashes & ANRs
- **Web**: Browser console, Sentry/LogRocket

### 2. Monitor User Feedback

- App Store reviews
- Play Store reviews
- Support emails
- Analytics events

### 3. Plan Next Release

- Prioritize bug fixes
- Plan new features
- Update roadmap

## Continuous Integration/Deployment (CI/CD)

### GitHub Actions Example

Create `.github/workflows/release.yml`:

```yaml
name: Release Builds

on:
  push:
    tags:
      - 'v*'

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd app && flutter pub get
      - run: cd app && flutter build ipa --release
      - uses: actions/upload-artifact@v3
        with:
          name: ios-release
          path: app/build/ios/ipa/*.ipa

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd app && flutter pub get
      - run: cd app && flutter build appbundle --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: app/build/app/outputs/bundle/release/*.aab

  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd app && flutter pub get
      - run: cd app && flutter build web --release --web-renderer canvaskit
      - uses: actions/upload-artifact@v3
        with:
          name: web-release
          path: app/build/web/
```

## Troubleshooting

### iOS: "No profiles for bundle identifier"

**Solution**: Configure signing in Xcode or use automatic signing

### Android: "Keystore was tampered with or password incorrect"

**Solution**: Verify password in `key.properties` matches keystore password

### Web: CORS errors in production

**Solution**: Configure CORS headers on API server to allow your domain

### Build fails with "Out of memory"

**Solution**: Increase Gradle memory in `android/gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx4096M -XX:MaxPermSize=1024m -XX:+HeapDumpOnOutOfMemoryError
```

---

**Last Updated**: 2024-12-20  
**Version**: 1.0  
**For Questions**: Contact DevOps team
