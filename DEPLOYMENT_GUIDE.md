# Firebase Cloud Functions Deployment Guide

## Prerequisites

### 1. Firebase Blaze Plan (Pay-as-you-go)
- **Required for**: Scheduled Cloud Functions (daily reminders, weekly reports, inactive user targeting)
- **Cost Estimate**: $1-5/month for 15 pilot study users
- **Upgrade at**: [Firebase Console](https://console.firebase.google.com) → Project Settings → Usage and billing

### 2. Install Required Tools
```bash
# Install Node.js 18+ (if not installed)
# Download from: https://nodejs.org/

# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version
```

### 3. Install Flutter Dependencies
```bash
cd selfcare_app

# Get new dependencies (cloud_functions, device_info_plus)
flutter pub get

# Verify no errors
flutter analyze
```

## Firebase Cloud Functions Deployment

### Step 1: Login to Firebase
```bash
cd firebase_functions
firebase login
```
This will open a browser for Google account authentication.

### Step 2: Select Firebase Project
```bash
# List available projects
firebase projects:list

# Set active project (should be "selfcare-bloom")
firebase use selfcare-bloom
```

### Step 3: Install Function Dependencies
```bash
cd functions
npm install
```

Expected output:
```
added 500+ packages in 30s
```

### Step 4: Deploy Functions
```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:sendDailyReminder,functions:sendInactiveUserReminder
```

Expected deployment output:
```
✔ functions[sendDailyReminder(us-central1)] Successful create operation
✔ functions[sendInactiveUserReminder(us-central1)] Successful create operation
✔ functions[sendWeeklyReport(us-central1)] Successful create operation
✔ functions[onAchievementUnlock(us-central1)] Successful create operation
✔ functions[storeFCMToken(us-central1)] Successful create operation
✔ functions[updateNotificationPreferences(us-central1)] Successful create operation
```

### Step 5: Verify Deployment
```bash
# List deployed functions
firebase functions:list

# View function logs
firebase functions:log
```

## Scheduled Function Times (East Africa Time - UTC+3)

| Function | Schedule | Purpose |
|----------|----------|---------|
| sendDailyReminder | 9:00 AM daily | Send check-in reminder to users who haven't assessed today |
| sendInactiveUserReminder | 2:00 PM daily | Re-engage users inactive for 7+ days |
| sendWeeklyReport | 8:00 PM Sunday | Send weekly progress summary with stats |
| onAchievementUnlock | Real-time trigger | Celebrate achievement unlocks |

## Testing the System

### Test 1: Registration Flow
1. **Open app** → Should show LoginScreen
2. **Tap "Don't have an account? Sign Up"**
3. **Fill registration form**:
   - Full Name: "Test User"
   - Email: "test@example.com"
   - Password: "test1234"
   - Confirm Password: "test1234"
   - Check "I agree to Terms & Privacy Policy"
4. **Tap "Create Account"**
5. **Verify**:
   - ✓ Success message: "Account created successfully! Welcome! 🎉"
   - ✓ Navigates to DashboardScreen
   - ✓ Firebase Console → Authentication → Shows new user
   - ✓ Firebase Console → Firestore → users/{userId} document exists
   - ✓ Check `notificationPreferences` field (all should be `true`)
   - ✓ Check `tokens` subcollection has device token

### Test 2: Login Flow
1. **Sign out** from dashboard (Profile → Sign Out)
2. **Enter email and password**
3. **Tap "Sign In"**
4. **Verify**:
   - ✓ Navigates to DashboardScreen
   - ✓ Profile button appears in AppBar
   - ✓ Device token updated in Firestore

### Test 3: Anonymous Login
1. **Tap "Continue Anonymously"**
2. **Verify**:
   - ✓ Navigates to dashboard
   - ✓ Profile → Shows "Anonymous Account" badge
   - ✓ Firebase Auth shows anonymous user

### Test 4: Password Reset
1. **Login screen** → Tap "Forgot Password?"
2. **Enter email**: "test@example.com"
3. **Tap "Send Reset Link"**
4. **Verify**:
   - ✓ Shows success view: "Check Your Email"
   - ✓ Email received with Firebase password reset link
   - ✓ Click link → Opens Firebase password reset page
   - ✓ Set new password → Can login with new password

### Test 5: Profile Management
1. **Dashboard** → Tap **person icon** (Profile)
2. **Verify profile shows**:
   - ✓ Avatar with user initials
   - ✓ Display name with edit button
   - ✓ Email address
   - ✓ Assessments Completed count
   - ✓ Achievements Unlocked count
3. **Tap edit icon** → Change name → **Tap check icon**
4. **Verify**: Success SnackBar + name updated
5. **Tap "Change Password"**
   - Enter current password
   - Enter new password (min 6 chars)
   - Confirm new password
6. **Verify**: Success message

### Test 6: Firebase Cloud Functions

#### Test Daily Reminder Function
```bash
# View function logs
firebase functions:log --only sendDailyReminder

# Manual trigger (for testing without waiting for 9 AM)
firebase functions:shell
> sendDailyReminder()
```

**Expected behavior**:
- Queries users with `dailyReminder: true`
- Checks if user completed assessment today
- Sends notification only if no assessment today
- Logs: "Successfully sent X notifications"

**Test in app**:
1. **Complete an assessment** at 8:00 AM
2. **Wait for 9:00 AM** scheduled function
3. **Verify**: NO notification received (already assessed today)
4. **Next day at 9:00 AM** without assessment
5. **Verify**: Notification received: "💙 Daily Check-In"

#### Test Inactive User Reminder
**Setup**:
1. Firebase Console → Firestore → users/{userId}
2. Set `lastAssessmentDate` to 8 days ago:
   ```javascript
   // In Firebase Console
   lastAssessmentDate: firebase.firestore.Timestamp.fromDate(
     new Date('2025-01-04T10:00:00Z')  // 8 days ago
   )
   ```

**Expected at 2:00 PM**:
- Notification received: "🌱 We Miss You!"
- Body: "It's been a week since your last check-in. How are you doing?"

#### Test Weekly Report
**Setup**:
1. Complete 3-5 assessments during the week
2. Each assessment has `totalScore` field (PSS score)

**Expected on Sunday at 8:00 PM**:
- Notification received: "📊 Your Weekly Progress"
- Body: "You completed 5 assessment(s) this week! Avg stress: 18/40"

#### Test Achievement Unlock
**Trigger**:
1. Complete first assessment (unlocks "First Step" achievement)
2. Achievement tracking creates document in `achievements` subcollection

**Expected immediately**:
- Notification received: "🏆 Achievement Unlocked!"
- Body: "🌱 First Step: Complete your first assessment"

## Monitoring & Debugging

### View Cloud Function Logs
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only sendDailyReminder

# Live tail (real-time)
firebase functions:log --only sendDailyReminder --tail
```

### Firebase Console Monitoring
1. **Firebase Console** → Functions
2. Click function name → **Logs tab**
3. View:
   - Execution count
   - Error count
   - Execution time
   - Memory usage

### Common Issues & Solutions

#### Issue: "Function execution took too long"
**Solution**: Increase timeout in functions/index.js:
```javascript
exports.sendDailyReminder = functions
  .runWith({ timeoutSeconds: 300 })  // 5 minutes
  .pubsub.schedule('0 9 * * *')
```

#### Issue: "Insufficient permissions"
**Solution**: Check Firestore rules allow Cloud Functions access:
```javascript
match /users/{userId} {
  allow read, write: if request.auth != null;
  allow read, write: if request.auth.token.admin == true;  // For functions
}
```

#### Issue: "FCM token not stored"
**Check**:
1. Firebase Console → Firestore → users/{userId}/tokens
2. Should contain documents with device IDs
3. If empty, check app logs: `print('FCM token stored successfully')`

#### Issue: "Notifications not received"
**Debug steps**:
1. Check FCM token exists in Firestore
2. Verify function executed (check logs)
3. Test FCM directly:
   ```bash
   # Get token from Firestore
   # Send test message:
   curl -X POST https://fcm.googleapis.com/fcm/send \
     -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "DEVICE_FCM_TOKEN",
       "notification": {
         "title": "Test",
         "body": "Test notification"
       }
     }'
   ```

## Cost Management

### Expected Costs (15 pilot users)
- **Cloud Functions Invocations**:
  - Daily reminders: 15 users × 30 days = 450 calls/month
  - Inactive reminders: 15 users × 30 days = 450 calls/month
  - Weekly reports: 15 users × 4 weeks = 60 calls/month
  - Achievement triggers: ~5 per user = 75 calls/month
  - **Total**: ~1,035 calls/month (well within 2M free tier)

- **Cloud Functions Compute Time**:
  - ~30 seconds/batch = 517 seconds/month = **$0.01-0.05**

- **Outbound Networking**: Negligible (<1 GB/month)

- **Firestore Reads/Writes**: 
  - ~5,000 reads + 1,000 writes = **$0.30-0.50**

**Total Estimated Cost**: **$1-5/month**

### Monitor Usage
1. Firebase Console → Usage and billing
2. Set budget alerts at $5, $10
3. Review monthly charges

## Production Checklist

- [ ] Firebase Blaze plan activated
- [ ] All 6 Cloud Functions deployed successfully
- [ ] Scheduled functions show in Firebase Console → Functions
- [ ] Test user registration → Firestore document created
- [ ] Test login → FCM token stored in tokens subcollection
- [ ] Test password reset → Email received
- [ ] Test profile management → Name/password changes work
- [ ] Test daily reminder → Notification received (or check logs)
- [ ] Test inactive user reminder → Set lastAssessmentDate to 8 days ago
- [ ] Test weekly report → Wait for Sunday 8 PM or trigger manually
- [ ] Test achievement unlock → Complete assessment → Notification received
- [ ] Budget alerts configured
- [ ] Firestore security rules reviewed

## Next Steps

### 1. Create Notification Preferences Screen (Optional)
Allow users to control which notifications they receive:
```dart
// lib/screens/notification_settings_screen.dart
SwitchListTile(
  title: 'Daily Reminders',
  value: _dailyReminder,
  onChanged: (value) async {
    await FirebasePushService.updateNotificationPreferences(
      dailyReminder: value,
      weeklyReport: _weeklyReport,
      achievementUnlocks: _achievementUnlocks,
    );
  },
)
```

Link from ProfileScreen:
```dart
ListTile(
  leading: Icon(Icons.notifications),
  title: Text('Notification Settings'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationSettingsScreen()),
    );
  },
)
```

### 2. Test with Pilot Users
1. Recruit 3-5 pilot users
2. Provide test credentials or registration link
3. Monitor engagement:
   - Daily login rate
   - Assessment completion rate
   - Notification interaction rate
4. Collect feedback on notification timing and frequency

### 3. Analyze Engagement Metrics
Firebase Analytics events to track:
- `daily_reminder_received`
- `daily_reminder_opened`
- `assessment_completed_after_reminder`
- `weekly_report_opened`
- `achievement_notification_opened`

Calculate:
- Notification → Assessment conversion rate
- Inactive user re-engagement success rate
- Weekly report engagement rate

### 4. Iterate Based on Data
Adjust notification timing if needed:
```javascript
// functions/index.js
// Change from 9 AM to 10 AM if that's when users are most active
exports.sendDailyReminder = functions.pubsub
  .schedule('0 10 * * *')  // 10 AM instead of 9 AM
  .timeZone('Africa/Nairobi')
```

## Support Resources

- **Firebase Functions Docs**: https://firebase.google.com/docs/functions
- **Schedule Functions**: https://firebase.google.com/docs/functions/schedule-functions
- **FCM Docs**: https://firebase.google.com/docs/cloud-messaging
- **Firestore Security Rules**: https://firebase.google.com/docs/firestore/security/get-started

## Troubleshooting Contact

If deployment issues persist:
1. Check Firebase Status: https://status.firebase.google.com/
2. Review function logs: `firebase functions:log`
3. Test in emulator: `firebase emulators:start --only functions`
4. Firebase Support: https://firebase.google.com/support
