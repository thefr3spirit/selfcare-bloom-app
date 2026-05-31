# SelfCare Together - Build & Deployment Guide

## Quick Start (First Time Setup)

### 1. Install Flutter

If you haven't installed Flutter yet:

```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install
# Add Flutter to your PATH

# Verify installation
flutter doctor
```

### 2. Setup Project

```bash
cd selfcare_app

# Get dependencies
flutter pub get

# Generate Hive type adapters (IMPORTANT!)
flutter pub run build_runner build --delete-conflicting-outputs
```

**Note:** The `build_runner` command generates the `*.g.dart` files needed for Hive database. You must run this before building the app!

### 3. Run on Device/Emulator

```bash
# Connect Android device via USB or start emulator
# Enable USB debugging on physical device

# Check connected devices
flutter devices

# Run app
flutter run
```

## Building Release APK

### For Distribution (All Devices)

```bash
# Clean previous builds
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Build release APK (universal)
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### For Specific Architecture (Smaller Size)

```bash
# For most modern phones (ARM64)
flutter build apk --release --target-platform android-arm64

# For older 32-bit phones
flutter build apk --release --target-platform android-arm

# For both (split APKs - smallest individual sizes)
flutter build apk --release --split-per-abi
```

## Installing APK on Devices

### Method 1: Direct USB Install

```bash
# Install to connected device
flutter install

# Or use adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Manual Transfer

1. Copy `app-release.apk` to device downloads folder
2. On device: Open Files app → Downloads → Tap APK
3. Allow "Install from unknown sources" if prompted
4. Tap "Install"

### Method 3: Share via Email/WhatsApp

1. Email the APK file to yourself
2. Open email on phone
3. Download and install APK

## Testing Checklist

### Before Distribution

- [ ] App installs successfully
- [ ] Consent screen appears on first launch
- [ ] Can complete full PSS-10 assessment
- [ ] Can select stressors and rate severity
- [ ] Can select coping strategies
- [ ] Recommendations generate correctly
- [ ] Crisis detection works (test with high PSS score)
- [ ] Data persists after app restart
- [ ] Notifications work (wait for scheduled time or test)
- [ ] Export functionality works (CSV generated and shareable)
- [ ] Airplane mode test (works offline)

### Test Scenarios

**Scenario 1: Low Stress User**
- PSS responses: Mostly "Never" and "Almost Never"
- Few stressors, low severity (1-3)
- Active coping strategies rated "Very effective"
- Expected: Low stress, preventive recommendations

**Scenario 2: Moderate Stress User**
- PSS responses: Mix of "Sometimes" and "Fairly Often"
- Several stressors, moderate severity (5-7)
- Mix of passive and active coping
- Expected: Moderate stress, skill-building recommendations

**Scenario 3: Crisis User**
- PSS responses: Mostly "Fairly Often" and "Very Often"
- Multiple severe stressors (8-10)
- Only passive coping rated "Not effective"
- Expected: High stress, crisis interventions with hotlines

## Troubleshooting

### Build Errors

**Error: "No *.g.dart files found"**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Error: "Android license status unknown"**
```bash
flutter doctor --android-licenses
```

**Error: "Gradle build failed"**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Runtime Errors

**Error: "HiveError: Box not found"**
- Uninstall app completely
- Reinstall fresh APK

**Notifications not working:**
- Check Android notification permissions in Settings
- Ensure Android 13+ permission granted

**Export not working:**
- Check storage permissions
- Try different share target (email vs WhatsApp)

## Updating the App

When you make code changes:

```bash
# 1. If you changed models (*.dart files with @HiveType)
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Rebuild APK
flutter build apk --release

# 3. Version the APK for tracking
cp build/app/outputs/flutter-apk/app-release.apk \
   releases/selfcare_v1.0_$(date +%Y%m%d).apk
```

## Performance Optimization

### Reduce APK Size

```bash
# Enable code shrinking and obfuscation
flutter build apk --release --shrink --obfuscate --split-debug-info=build/debug-info
```

### For Low-End Devices

- Already optimized: No heavy dependencies
- Offline-first: No network calls
- Simple UI: Material Design 3
- Efficient storage: Hive (NoSQL, fast)

## Data Management

### Backup User Data

Users can export data anytime via:
1. Dashboard → Export button (share icon)
2. Generates CSV with all assessments
3. Share via email/WhatsApp

### Clear App Data (For Testing)

```bash
# On device: Settings → Apps → SelfCare Together → Storage → Clear Data
# Or via adb:
adb shell pm clear com.example.selfcare_together
```

## Distribution Checklist

Before sending APKs to volunteers:

- [ ] Test on at least 2 different devices
- [ ] Test both online and offline
- [ ] Verify crisis hotlines are correct (Uganda/Kenya)
- [ ] Confirm notifications work
- [ ] Test export and share functionality
- [ ] Create simple user guide (PDF)
- [ ] Prepare support contact information

## User Guide (To Share with Volunteers)

### First Time Setup

1. Install APK from email/WhatsApp
2. Open app, read and accept consent
3. Enter your name (required), age and gender (optional)
4. Tap "Get Started"

### Taking Assessment

1. Tap "Take Assessment" on dashboard
2. Answer all 10 PSS questions honestly
3. Select stressors affecting you (rate 1-10)
4. Select coping strategies you use
5. Tap "Finish"

### Viewing Recommendations

- Recommendations appear immediately after assessment
- Tap each card to expand and read details
- Crisis recommendations (red) need immediate attention
- Mark recommendations as viewed after reading

### Exporting Data

1. Tap share icon in top right of dashboard
2. Select email, WhatsApp, or other app
3. Send to researcher

### Notifications

- App reminds you every 2 days (8 PM)
- You can disable in Settings if needed

### Support

- Contact: [Your email/phone]
- App works 100% offline
- Your data stays on your device

## Timeline

- **Day 1-2:** Build and test APK
- **Day 3:** Distribute to 2-3 beta testers
- **Day 4-5:** Fix any issues from beta
- **Day 6:** Distribute to remaining volunteers
- **Week 2+:** Monitor participation, collect feedback

## Post-Pilot

### Collecting Data

1. Ask volunteers to export and send CSV
2. Consolidate all CSV files
3. Analyze in Python (using your existing analysis scripts)

### Improvements for V2

- Add trend charts
- Add goal setting
- Add progress tracking
- Add more languages
- Consider cloud sync option

---

**Questions?**

Contact the development team for support during pilot phase.

**Emergency:**

If critical bug is found, immediately:
1. Document the issue
2. Pull the APK from circulation
3. Fix bug
4. Rebuild and retest
5. Redistribute with version number increment
