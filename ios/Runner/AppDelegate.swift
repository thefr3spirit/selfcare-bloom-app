import Flutter
import UIKit

// Conforms to FlutterImplicitEngineDelegate (available since Flutter 3.38,
// when UIScene support was added) so plugin registration actually happens.
// Under the UIScene lifecycle (see Info.plist's UIApplicationSceneManifest,
// which points at Flutter's own FlutterSceneDelegate), the Flutter engine is
// created later/differently than before, and super.application(_:didFinishLaunchingWithOptions:)
// no longer registers plugins on its own the way it used to — that must now
// happen in didInitializeImplicitFlutterEngine(_:), or NO plugin (including
// firebase_auth, google_sign_in, sign_in_with_apple) ever gets registered,
// and every method-channel call throws MissingPluginException at runtime
// despite building/archiving/signing successfully.
// https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
