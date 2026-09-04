import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase Authentication Service
/// Handles user authentication (email/password, Google, Apple, anonymous)
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // The web client ID (OAuth type 3) is required on Android so that
    // GoogleSignInAuthentication.idToken is populated. Without it the
    // Firebase credential will be missing an idToken and sign-in fails.
    serverClientId:
        '886791280277-r5m769fp5qk64353g4vnq1ikbbutqm2s.apps.googleusercontent.com',
  );

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Sign in anonymously (no email/password required)
  /// Perfect for pilot study - preserves privacy
  static Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      debugPrint('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      return null;
    }
  }

  /// Sign up with email and password
  static Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
      }

      debugPrint('Signed up successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Sign-up failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Signed in: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  static Future<User?> signInWithGoogle() async {
    try {
      // Force account picker by clearing any cached Google session first
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        debugPrint('Google sign-in cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('Signed in with Google: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      rethrow;
    }
  }

  /// Generates a cryptographically secure random nonce for Apple Sign-In.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Sign in with Apple
  static Future<User?> signInWithApple() async {
    try {
      // Generate a random nonce and its SHA-256 hash. The raw nonce is sent
      // to Firebase, while the hashed nonce is sent to Apple — this proves
      // the ID token was requested by this app and not replayed by an attacker.
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        // Apple only ever provides the user's name on the very first
        // sign-in, so capture it now before it's lost for good.
        final appleFullName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((s) => s != null && s.isNotEmpty).join(' ');

        if (appleFullName.isNotEmpty &&
            (user.displayName == null || user.displayName!.isEmpty)) {
          await user.updateDisplayName(appleFullName);
          await user.reload();
        }
      }

      debugPrint('Signed in with Apple: ${user?.uid}');
      return user;
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      debugPrint('Failed to send password reset email: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      debugPrint('User profile updated');
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      rethrow;
    }
  }

  /// Change user password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user');
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
      debugPrint('Password changed successfully');
    } catch (e) {
      debugPrint('Failed to change password: $e');
      rethrow;
    }
  }

  /// Delete user account (email/password or anonymous)
  static Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Re-authenticate if not anonymous
      if (!user.isAnonymous && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      await user.delete();
      debugPrint('Account deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete account: $e');
      rethrow;
    }
  }

  /// Delete user account (Google sign-in)
  static Future<void> deleteGoogleAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Re-authenticate with Google before deletion
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google re-authentication cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);

      await user.delete();
      await _googleSignIn.signOut();
      debugPrint('Google account deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete Google account: $e');
      rethrow;
    }
  }

  /// Delete user account (Apple sign-in)
  static Future<void> deleteAppleAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Re-authenticate with Apple before deletion
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      await user.reauthenticateWithCredential(oauthCredential);

      await user.delete();
      debugPrint('Apple account deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete Apple account: $e');
      rethrow;
    }
  }

  /// Which provider the current user signed in with: 'apple.com', 'google.com',
  /// 'password', or null if signed in anonymously / not signed in.
  static String? getAuthProviderId() {
    final user = _auth.currentUser;
    if (user == null || user.providerData.isEmpty) return null;
    return user.providerData.first.providerId;
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Check if user is anonymous
  static bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? true;
  }

  /// Sign out — clears Firebase session and Google cached account
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Get user ID (for associating data)
  static String? getUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get user email
  static String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Get user display name
  static String? getUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  // ============================================================================
  // CLOUD DATA BACKUP
  // ============================================================================
  // Firestore-backed cloud sync/backup/analytics were removed (cloud_firestore
  // and cloud_functions pull in a gRPC/abseil/leveldb/nanopb C++ dependency
  // chain that App Store Connect rejects at upload validation with "No
  // architectures in the binary" — confirmed via bisection, see git history).
  // The app is offline-first (Hive) by design, so these are now no-ops kept
  // only so existing call sites don't need to change.

  /// No-op: recommendation feedback backup (cloud sync removed)
  static Future<void> backupFeedback(Map<String, dynamic> feedbackData) async {
    debugPrint('Feedback backup skipped (cloud sync disabled)');
  }
}
