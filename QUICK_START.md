# SelfCare Together - Quick Command Reference

## Essential Commands

### First Time Setup
```bash
cd selfcare_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run on Device
```bash
flutter run
```

### Build Release APK
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

**APK Location:** `build/app/outputs/flutter-apk/app-release.apk`

### Install APK
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### When You Change Models
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Check Connected Devices
```bash
flutter devices
```

### View Logs
```bash
flutter logs
```

### Clear App Data (Testing)
```bash
adb shell pm clear com.example.selfcare_together
```

## Troubleshooting One-Liners

```bash
# Fix build_runner issues
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# Fix Gradle issues
cd android && ./gradlew clean && cd .. && flutter clean && flutter pub get

# Fix license issues
flutter doctor --android-licenses

# Reinstall dependencies
flutter pub cache repair
flutter pub get
```

## Testing Shortcuts

```bash
# Hot reload (while app is running)
# Press 'r' in terminal

# Hot restart (while app is running)
# Press 'R' in terminal

# Open DevTools
# Press 'v' in terminal

# Quit
# Press 'q' in terminal
```

## That's It!

Your complete offline-first Flutter app is ready! 🎉

**Next steps:**
1. Run `flutter pub get`
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Run `flutter run` or build APK
4. Test thoroughly
5. Distribute to volunteers

Good luck with your pilot study!
