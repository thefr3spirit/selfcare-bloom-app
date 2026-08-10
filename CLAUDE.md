# SelfCare Together (Selfcare & Bloom)

Flutter app for stress management / mental health pilot study (Uganda/Kenya). Offline-first (Hive local storage) with Firebase for auth, cloud sync/backup, and push notifications. Ships to both Android and iOS (bundle id `com.selfcarebloom.app`).

This directory (`selfcare_app/`) is the actual Flutter project and git repo root — everything above it (`D:\SelfCareTogether\`) is research/analysis material for the underlying study, not part of the app.

Repo: `https://github.com/thefr3spirit/selfcare-bloom-app` (branch `main`).

## Cross-device workflow

Development happens on this Windows PC; iOS builds happen on a Mac (currently a cousin's, borrowed access) since Windows can't build/archive iOS. The loop is: edit here → commit/push → `git pull` on the Mac → build & upload to App Store Connect from Xcode. Always `git pull` at the start of a session before making changes, and push when done so the Mac side can pick it up.

**Codemagic CI was tried and abandoned** (it failed) in favor of the Mac. `codemagic.yaml` has been deleted — don't reintroduce a cloud CI pipeline unless explicitly asked.

## iOS build/signing

- `CODE_SIGN_STYLE = Automatic` in `ios/Runner.xcodeproj/project.pbxproj`, team `C26VK7Y2WB`.
- `ExportOptions.plist` at the repo root (`signingStyle: automatic`) is what the Mac uses to archive/export. This is the only export options file that matters now.
- `ios/Podfile` has a heavily-customized `post_install` block (strips embedded provisioning profiles from frameworks, patches `set -u` scripts, injects `Info.plist` into `Flutter.framework` for Xcode 26+, etc.) — these were all fixes for real App Store Connect upload failures. Don't simplify/remove those without understanding why each exists (see git log for the individual `fix:` commits).
- `ITSAppUsesNonExemptEncryption = false` is set in `ios/Runner/Info.plist` to skip the export-compliance prompt (app only uses standard TLS).

## Authentication

Four sign-in methods: email/password, Google, **Apple**, and anonymous. Apple Sign-In was added because App Store review rejected the app under Guideline 4.8 for offering Google sign-in without an Apple equivalent.

- Implementation: `lib/services/firebase_service.dart` (`signInWithApple`, `deleteAppleAccount`, plus the pre-existing Google/email/anonymous equivalents). Apple uses the standard secure-nonce flow (`sign_in_with_apple` package + Firebase `OAuthProvider('apple.com')`).
- Capability: `ios/Runner/Runner.entitlements` (`com.apple.developer.applesignin`), wired into all 3 build configs via `CODE_SIGN_ENTITLEMENTS`.
- External config (already done, don't redo): Sign In with Apple capability enabled on the App ID in Apple Developer Portal; Apple provider enabled in Firebase Console → Authentication.
- Apple's sign-in button only renders on iOS (`Platform.isIOS` check) in `lib/screens/auth/login_screen.dart` and `register_screen.dart`.

**Gotcha:** account deletion is implemented independently in *two* screens — `lib/screens/profile_screen.dart` and `lib/screens/settings_screen.dart` (both are reachable in the app; not dead code). Each branches on `providerData` to pick the right re-auth path (`password` needs a password prompt + `EmailAuthProvider`; `google.com` / `apple.com` need their own re-auth + `deleteGoogleAccount()` / `deleteAppleAccount()`; anonymous needs neither). If you touch one, check the other — they've drifted out of sync before (that's how the Google-account deletion bug was found while adding Apple).

## Status / next steps

- Apple Sign-In code is committed and pushed; external Apple Developer Portal + Firebase config is done.
- **Not yet verified**: no real-device/TestFlight test of the Apple sign-in + delete-account flow yet. Do that before resubmitting to App Store review.
- `flutter analyze` is clean (only pre-existing `use_build_context_synchronously` info-level lints, same pattern used throughout the codebase — not new issues).
