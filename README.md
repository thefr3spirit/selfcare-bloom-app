# SelfCare Together - Flutter App

Offline-first mental health and stress management app for pilot study in East Africa (Uganda/Kenya).

## Features

- ✅ PSS-10 stress assessment
- ✅ Stressor tracking with severity ratings
- ✅ Rule-based recommendation algorithm (offline)
- ✅ Local data storage (Hive)
- ✅ Stress trend visualization
- ✅ Push notifications for reassessment reminders
- ✅ CSV data export via share sheet
- ✅ Crisis detection with East Africa hotlines
- ✅ Fully offline capable

## Setup Instructions

### Prerequisites

- Flutter SDK 3.0+
- Android Studio or VS Code with Flutter extension
- Android device/emulator (API 24+ / Android 7.0+)

### Installation

1. **Install dependencies:**
   ```bash
   cd selfcare_app
   flutter pub get
   flutter pub run build_runner build
   ```

2. **Run on device:**
   ```bash
   flutter run
   ```

3. **Build APK for distribution:**
   ```bash
   flutter build apk --release
   ```
   
   APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Testing Offline Mode

1. Enable Airplane mode on device
2. Launch app
3. Complete assessment
4. Verify recommendations appear
5. Check data persists after app restart

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/                            # Data models
│   ├── user_profile.dart
│   ├── pss_assessment.dart
│   ├── stressor.dart
│   ├── coping_strategy.dart
│   ├── recommendation.dart
│   └── app_settings.dart
├── services/                          # Business logic
│   ├── storage_service.dart          # Hive database
│   ├── algorithm_service.dart        # Recommendation engine
│   ├── notification_service.dart     # Local notifications
│   └── export_service.dart           # CSV export
├── screens/                           # UI screens
│   ├── consent_screen.dart
│   ├── dashboard_screen.dart
│   ├── assessment_screen.dart
│   ├── recommendations_screen.dart
│   └── settings_screen.dart
└── widgets/                           # Reusable components
    ├── pss_question_card.dart
    ├── stressor_card.dart
    ├── recommendation_card.dart
    └── stress_trend_chart.dart
```

## Data Storage

All data stored locally using Hive (NoSQL):
- User profile and consent
- PSS-10 assessments with timestamps
- Stressor severity ratings
- Recommendations history
- App settings

## Export Format

CSV export includes:
- User ID and name
- All PSS assessment scores with dates
- Stressor ratings over time
- Recommendations generated
- Crisis events logged

## Build for Production

```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Release APK
flutter build apk --release --target-platform android-arm64

# For older devices (32-bit)
flutter build apk --release --target-platform android-arm
```

## Troubleshooting

**Issue:** Build runner errors
**Fix:** `flutter pub run build_runner build --delete-conflicting-outputs`

**Issue:** Notifications not working
**Fix:** Check Android notification permissions in device settings

**Issue:** Export not saving
**Fix:** Check storage permissions in device settings

## Timeline

- Development: 3-4 days
- Testing: 2-3 days
- Pilot deployment: 1 week from approval

## Contact

For technical issues during pilot, contact the research team.
