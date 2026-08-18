# SelfCare Together (Selfcare & Bloom)

Flutter app for stress management / mental health pilot study (Uganda/Kenya). Offline-first (Hive local storage) with Firebase for auth, cloud sync/backup, and push notifications. Ships to both Android and iOS (bundle id `com.selfcarebloom.app`).

This directory (`selfcare_app/`) is the actual Flutter project and git repo root — everything above it (`D:\SelfCareTogether\`) is research/analysis material for the underlying study, not part of the app.

Repo: `https://github.com/thefr3spirit/selfcare-bloom-app` (branch `main`).

## Cross-device workflow

Development happens on this Windows PC. iOS builds **used to** happen on a cousin's Mac, but that access is gone as of 2026-08-18 — there is no Mac in the loop anymore.

**iOS builds now happen via GitHub Actions** (`.github/workflows/ios-testflight.yml`), triggered manually (`workflow_dispatch` — every run attempts a real App Store Connect upload and consumes a build number, so it doesn't run on every push). It uses a hosted macOS runner + an App Store Connect API key for automatic signing (`xcodebuild -allowProvisioningUpdates -authenticationKeyPath/-authenticationKeyID/-authenticationKeyIssuerID`), so nothing needs to be exported from the old Mac's keychain. Required repo secrets: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8` (the raw `.p8` contents) — generate the key at App Store Connect → Users and Access → Integrations → App Store Connect API (Admin role), no Mac required.

**Codemagic CI was tried once before and abandoned** (failed on an SPM build-flag error, before most of the current Podfile fixes existed). GitHub Actions was chosen instead because the repo is public, so macOS runner minutes are free/unmetered (Codemagic's free tier is capped). If the GitHub Actions workflow also turns out to be unworkable, that's the fallback to reconsider — but try to fix the workflow first.

Bump `pubspec.yaml`'s build number (`+N` after `1.0.0`) past whatever Apple last reviewed before triggering a new upload — Apple rejects re-uploads at or below an already-seen build number. Check the last rejection email's "Version reviewed" line if unsure.

## iOS build/signing

- `CODE_SIGN_STYLE = Automatic` in `ios/Runner.xcodeproj/project.pbxproj`, team `C26VK7Y2WB`.
- `ExportOptions.plist` at the repo root (`signingStyle: automatic`, `method: app-store`) was what the Mac used to archive/export interactively — kept for reference / possible future manual use, but nothing currently reads it.
- `ios/ExportOptions-ci.plist` is what the GitHub Actions workflow actually uses (`method: app-store-connect`, `destination: upload` — exports and uploads to App Store Connect in one `xcodebuild -exportArchive` step, no separate altool/Transporter step needed).
- `ios/Podfile` has a heavily-customized `post_install` block (strips embedded provisioning profiles from frameworks, patches `set -u` scripts, injects `Info.plist` into `Flutter.framework` for Xcode 26+, etc.) — these were all fixes for real App Store Connect upload failures. Don't simplify/remove those without understanding why each exists (see git log for the individual `fix:` commits).
- `ITSAppUsesNonExemptEncryption = false` is set in `ios/Runner/Info.plist` to skip the export-compliance prompt (app only uses standard TLS).
- **Known risk, not yet hit or fixed**: automatic signing via API key can only *download* an existing distribution certificate's public half — it can't recover a private key that only ever existed in the old Mac's keychain. If the Apple Developer account is already at its certificate limit from certs created on that Mac, the CI run will fail trying to create a new one. Fix: Apple Developer Portal → Certificates → revoke old/unused iOS Distribution certs to free a slot.

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
- Second rejection (guideline 1.4.1, missing citations for medical/health info) has been addressed: `lib/data/citations.dart`, `lib/screens/sources_screen.dart`, citation links wired into recommendations/settings screens. Also fixed while auditing for a third rejection: a stale-PSS-score navigation bug, an account-deletion path that left local data on-device, an inaccurate Privacy Policy (claimed encryption/analytics that don't exist), leftover `[placeholder]` text in Terms/Privacy, and Uganda/Kenya-only crisis resources with no international fallback.
- **The GitHub Actions iOS workflow (`.github/workflows/ios-testflight.yml`) has never been run** — it was written and reasoned through carefully but is untested against the real Apple Developer account/certs, since there's no Mac to cross-check against. Expect the first run(s) to need debugging from the Actions log, the same way the Podfile fixes were arrived at iteratively on the Mac. Needs the three `APP_STORE_CONNECT_*` secrets set in the repo before it can run at all.
