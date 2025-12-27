# Solitude - Build and Deployment Guide

Complete guide for building and deploying Solitude across all platforms.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Setup](#development-setup)
3. [Building for Web](#building-for-web)
4. [Building for Android](#building-for-android)
5. [Building for iOS](#building-for-ios)
6. [Building for Linux](#building-for-linux)
7. [Building for Windows](#building-for-windows)
8. [Building for macOS](#building-for-macos)
9. [Release Process](#release-process)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Flutter SDK

**Install Flutter:**

1. **Download Flutter:**
   - Visit https://flutter.dev/docs/get-started/install
   - Choose your operating system
   - Download the latest stable release

2. **Extract and add to PATH:**

   **Linux/macOS:**
   ```bash
   cd ~/development
   tar xf ~/Downloads/flutter_*.tar.xz
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

   Add to `~/.bashrc`, `~/.zshrc`, or equivalent:
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

   **Windows:**
   - Extract zip to `C:\src\flutter`
   - Add `C:\src\flutter\bin` to PATH via System Environment Variables

3. **Verify installation:**
   ```bash
   flutter doctor
   ```

   Address any issues reported by `flutter doctor`.

### Platform-Specific Requirements

#### All Platforms
- **Git:** https://git-scm.com/
- **IDE:** VS Code, Android Studio, or IntelliJ IDEA

#### Web
- **Chrome:** For testing and debugging

#### Android
- **Android Studio:** https://developer.android.com/studio
- **Android SDK:** Installed via Android Studio
- **Java JDK:** Version 11 or higher

#### iOS (macOS only)
- **Xcode:** Latest version from Mac App Store
- **CocoaPods:** `sudo gem install cocoapods`
- **Apple Developer Account:** For distribution

#### Linux
- **Clang and build tools:**
  ```bash
  # Ubuntu/Debian
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev

  # Fedora
  sudo dnf install clang cmake ninja-build gtk3-devel
  ```

#### Windows
- **Visual Studio 2022:** Community edition or higher
- **Desktop development with C++** workload installed

#### macOS
- **Xcode:** Latest version
- **Xcode Command Line Tools:** `xcode-select --install`

---

## Development Setup

### Clone Repository

```bash
git clone https://github.com/plotworx/solitude.git
cd solitude
```

### Install Dependencies

```bash
flutter pub get
```

### Verify Setup

```bash
# List available devices
flutter devices

# Run on preferred device
flutter run -d chrome           # Web
flutter run -d linux            # Linux
flutter run -d android          # Android
flutter run -d ios              # iOS
```

### Development Mode

```bash
# Hot reload enabled
flutter run

# Verbose logging
flutter run -v

# Debug mode with DevTools
flutter run --debug
```

---

## Building for Web

### Development Build

```bash
flutter run -d chrome
```

### Production Build

```bash
# Build optimized web app
flutter build web --release

# Output directory: build/web/
```

### Web Build Options

```bash
# Build with specific renderer
flutter build web --web-renderer canvaskit  # Better performance, larger size
flutter build web --web-renderer html       # Smaller size, less features

# Auto-detect best renderer (recommended)
flutter build web --web-renderer auto

# Base href for deployment in subdirectory
flutter build web --base-href /solitude/

# Minify JavaScript
flutter build web --release --no-tree-shake-icons
```

### Testing Production Build Locally

```bash
# Serve build directory
cd build/web
python3 -m http.server 8000

# Or use dhttpd
dart pub global activate dhttpd
dhttpd --path build/web
```

Visit `http://localhost:8000` in your browser.

### Deployment

#### GitHub Pages

```bash
# Build with base href
flutter build web --release --base-href "/solitude/"

# Copy to gh-pages branch
git checkout gh-pages
cp -r build/web/* .
git add .
git commit -m "Deploy version X.Y.Z"
git push origin gh-pages
```

#### Netlify

1. Build locally: `flutter build web --release`
2. Drag `build/web` folder to Netlify dashboard
3. Or connect GitHub repo for automatic deployments

**netlify.toml:**
```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

#### Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Build
flutter build web --release

# Deploy
vercel build/web
```

### Progressive Web App (PWA)

Solitude is PWA-ready:

**Features:**
- Installable on desktop and mobile
- Works offline (after first load)
- App-like experience

**manifest.json** (already configured):
```json
{
  "name": "Solitude",
  "short_name": "Solitude",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#2E7D32",
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
    }
  ]
}
```

---

## Building for Android

### Development Build

```bash
# Run on connected device/emulator
flutter run -d android
```

### Debug APK

```bash
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK

```bash
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Code Signing

**Create keystore:**

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**Configure signing** (`android/key.properties`):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/home/user/upload-keystore.jks
```

**Update** `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
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
        }
    }
}
```

### Build Variants

```bash
# Split APKs by ABI (smaller files)
flutter build apk --split-per-abi

# Generates:
# - app-armeabi-v7a-release.apk
# - app-arm64-v8a-release.apk
# - app-x86_64-release.apk
```

### Testing Release Build

```bash
# Install release APK
flutter install --release

# Or manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Play Store Deployment

1. **Build App Bundle:**
   ```bash
   flutter build appbundle --release
   ```

2. **Upload to Play Console:**
   - Go to Google Play Console
   - Create application
   - Upload `app-release.aab`
   - Fill store listing details
   - Submit for review

---

## Building for iOS

**Requirement:** macOS with Xcode installed.

### Development Build

```bash
# Run on simulator
flutter run -d ios

# Run on physical device (requires provisioning)
flutter run -d <device-id>
```

### Setup iOS Project

1. **Open in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure signing:**
   - Select "Runner" project
   - Go to "Signing & Capabilities"
   - Select your Team
   - Xcode will create provisioning profile

3. **Update Bundle ID:**
   - Change to unique identifier (e.g., `com.yourcompany.solitude`)

### Release Build

```bash
# Build for iOS
flutter build ios --release

# Or build archive for App Store
flutter build ipa
```

### App Store Deployment

1. **Build IPA:**
   ```bash
   flutter build ipa
   ```

2. **Upload to App Store Connect:**

   **Option A: Xcode**
   - Open `ios/Runner.xcworkspace`
   - Product → Archive
   - Distribute App → App Store Connect

   **Option B: Transporter**
   - Install Transporter from Mac App Store
   - Drag `build/ios/ipa/*.ipa` to Transporter
   - Upload to App Store Connect

3. **Submit for Review:**
   - Go to App Store Connect
   - Fill app information
   - Submit for review

### TestFlight Distribution

Same process as App Store, but select "TestFlight" instead of "App Store" in distribution options.

---

## Building for Linux

**Supported distributions:** Ubuntu 20.04+, Fedora 34+, Debian 11+

### Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

**Fedora:**
```bash
sudo dnf install clang cmake ninja-build gtk3-devel
```

### Development Build

```bash
flutter run -d linux
```

### Release Build

```bash
flutter build linux --release

# Output: build/linux/x64/release/bundle/
```

### Package as AppImage

**Install tools:**
```bash
# Download appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
```

**Create AppDir structure:**
```bash
mkdir -p Solitude.AppDir/usr/bin
mkdir -p Solitude.AppDir/usr/lib
mkdir -p Solitude.AppDir/usr/share/applications
mkdir -p Solitude.AppDir/usr/share/icons/hicolor/256x256/apps

# Copy binary and libs
cp -r build/linux/x64/release/bundle/* Solitude.AppDir/usr/bin/

# Create .desktop file
cat > Solitude.AppDir/usr/share/applications/solitude.desktop <<EOF
[Desktop Entry]
Name=Solitude
Exec=solitude
Icon=solitude
Type=Application
Categories=Game;CardGame;
EOF

# Copy icon
cp assets/icon.png Solitude.AppDir/usr/share/icons/hicolor/256x256/apps/solitude.png
cp assets/icon.png Solitude.AppDir/solitude.png

# Create AppRun
cat > Solitude.AppDir/AppRun <<EOF
#!/bin/bash
SELF=\$(readlink -f "\$0")
HERE=\${SELF%/*}
export PATH="\${HERE}/usr/bin/:\${PATH}"
export LD_LIBRARY_PATH="\${HERE}/usr/lib/:\${LD_LIBRARY_PATH}"
exec "\${HERE}/usr/bin/solitude" "\$@"
EOF
chmod +x Solitude.AppDir/AppRun

# Build AppImage
./appimagetool-x86_64.AppImage Solitude.AppDir Solitude-x86_64.AppImage
```

### Package as Snap

**snapcraft.yaml:**
```yaml
name: solitude
version: '1.0.0'
summary: Beautiful solitaire card game
description: |
  Cross-platform Klondike solitaire with beautiful themes,
  multiple difficulty levels, and comprehensive statistics.

base: core22
confinement: strict
grade: stable

apps:
  solitude:
    command: solitude
    extensions: [gnome]
    plugs:
      - home
      - audio-playback

parts:
  solitude:
    plugin: flutter
    source: .
    flutter-target: lib/main.dart
```

**Build:**
```bash
snapcraft
```

### Package as .deb

Use **flutter_distributor** or manually create package structure.

---

## Building for Windows

**Requirement:** Windows 10/11 with Visual Studio 2022.

### Install Visual Studio

1. Download Visual Studio 2022 Community
2. Install "Desktop development with C++" workload
3. Verify: `flutter doctor`

### Development Build

```bash
flutter run -d windows
```

### Release Build

```bash
flutter build windows --release

# Output: build\windows\x64\runner\Release\
```

### Create Installer with Inno Setup

**Install Inno Setup:**
- Download from https://jrsoftware.org/isdl.php

**Create installer script** (`installer.iss`):

```inno
[Setup]
AppName=Solitude
AppVersion=1.0.0
DefaultDirName={pf}\Solitude
DefaultGroupName=Solitude
OutputDir=installer
OutputBaseFilename=SolitudeSetup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Solitude"; Filename: "{app}\solitude.exe"
Name: "{autodesktop}\Solitude"; Filename: "{app}\solitude.exe"

[Run]
Filename: "{app}\solitude.exe"; Description: "Launch Solitude"; Flags: postinstall nowait skipifsilent
```

**Build installer:**
```bash
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

### Package as MSIX (Microsoft Store)

```bash
flutter build windows

# Use Windows App Certification Kit or Visual Studio
# to package as MSIX for Microsoft Store
```

---

## Building for macOS

**Requirement:** macOS with Xcode installed.

### Development Build

```bash
flutter run -d macos
```

### Release Build

```bash
flutter build macos --release

# Output: build/macos/Build/Products/Release/solitude.app
```

### Code Signing

**Configure signing:**

1. Open `macos/Runner.xcworkspace` in Xcode
2. Select "Runner" target
3. Go to "Signing & Capabilities"
4. Select your Team
5. Choose certificate

**Build signed app:**
```bash
flutter build macos --release
```

### Create DMG Installer

**Install create-dmg:**
```bash
brew install create-dmg
```

**Create DMG:**
```bash
create-dmg \
  --volname "Solitude" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "solitude.app" 175 120 \
  --hide-extension "solitude.app" \
  --app-drop-link 425 120 \
  "Solitude.dmg" \
  "build/macos/Build/Products/Release/solitude.app"
```

### Mac App Store Deployment

1. **Configure entitlements** (`macos/Runner/Release.entitlements`)
2. **Build archive** in Xcode (Product → Archive)
3. **Upload to App Store Connect**
4. **Submit for review**

### Notarization (for distribution outside App Store)

```bash
# Build signed app
flutter build macos --release

# Zip app
cd build/macos/Build/Products/Release
zip -r solitude.zip solitude.app

# Submit for notarization
xcrun notarytool submit solitude.zip \
  --apple-id your@email.com \
  --team-id TEAMID \
  --password app-specific-password \
  --wait

# Staple notarization ticket
xcrun stapler staple solitude.app
```

---

## Release Process

### Version Bumping

**Update** `pubspec.yaml`:
```yaml
version: 1.0.1+2  # version_name+build_number
```

**Commit:**
```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.1"
git tag v1.0.1
git push origin main --tags
```

### Build All Platforms

```bash
# Web
flutter build web --release

# Android
flutter build appbundle --release

# iOS
flutter build ipa

# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

### Create GitHub Release

1. Go to repository releases
2. Click "Draft a new release"
3. Choose tag: `v1.0.1`
4. Write release notes
5. Upload build artifacts:
   - `Solitude-web.zip` (build/web)
   - `app-release.aab` (Android)
   - `Solitude.ipa` (iOS)
   - `Solitude-x86_64.AppImage` (Linux)
   - `SolitudeSetup.exe` (Windows)
   - `Solitude.dmg` (macOS)
6. Publish release

### Changelog

**CHANGELOG.md:**
```markdown
## [1.0.1] - 2025-01-15

### Added
- Plum Royale theme
- Keyboard shortcut for settings (Esc)

### Fixed
- Audio not playing on Android 14
- Theme preview cards not updating

### Changed
- Improved overlay validation algorithm
```

---

## Troubleshooting

### General Issues

**Problem:** `flutter doctor` shows issues
**Solution:** Address each issue listed. Common:
- Update Flutter: `flutter upgrade`
- Accept Android licenses: `flutter doctor --android-licenses`
- Install Xcode command line tools: `xcode-select --install`

**Problem:** Dependencies not resolving
**Solution:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

**Problem:** Build fails with cryptic errors
**Solution:**
```bash
flutter clean
flutter pub get
flutter run --verbose  # Check detailed error
```

### Platform-Specific Issues

#### Web

**Problem:** Cards not displaying
**Solution:** Check SVG asset is included in `pubspec.yaml`

**Problem:** Audio not working
**Solution:** Browser security requires user interaction before audio

#### Android

**Problem:** Gradle build fails
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

**Problem:** Signing fails
**Solution:** Verify `key.properties` file exists and paths are correct

#### iOS

**Problem:** Provisioning profile errors
**Solution:** Delete derived data and rebuild in Xcode

**Problem:** Missing pods
**Solution:**
```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### Linux

**Problem:** Missing GTK libraries
**Solution:** Install dependencies (see Linux section above)

#### Windows

**Problem:** Visual Studio not found
**Solution:** Ensure VS 2022 with C++ workload is installed

#### macOS

**Problem:** Xcode build fails
**Solution:** Update to latest Xcode and accept license:
```bash
sudo xcodebuild -license accept
```

---

## Performance Optimization

### Build Size Optimization

```bash
# Remove debug symbols
flutter build <platform> --release --split-debug-info=<directory>

# Obfuscate code (makes debugging harder)
flutter build <platform> --release --obfuscate

# Tree shake icons (remove unused Material icons)
flutter build <platform> --release --tree-shake-icons
```

### Analyze Build

```bash
# Analyze build size
flutter build apk --analyze-size

# Generate size breakdown
flutter build appbundle --analyze-size --target-platform android-arm64
```

---

## CI/CD Integration

### GitHub Actions Example

**.github/workflows/build.yml:**
```yaml
name: Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'

    - name: Install dependencies
      run: flutter pub get

    - name: Analyze code
      run: flutter analyze

    - name: Run tests
      run: flutter test

    - name: Build web
      run: flutter build web --release

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./build/web
```

---

## Additional Resources

- **Flutter Documentation:** https://flutter.dev/docs
- **Platform-specific guides:** https://flutter.dev/docs/deployment
- **Performance best practices:** https://flutter.dev/docs/perf
- **CI/CD examples:** https://flutter.dev/docs/deployment/cd

---

**Happy building!**

Version 1.0.0
