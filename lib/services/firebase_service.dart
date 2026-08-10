import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase Authentication and Firestore Service
/// Handles user authentication and cloud data sync
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': displayName ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'totalAssessments': 0,
          'isAnonymous': false,
          'notificationPreferences': {
            'dailyReminder': true,
            'weeklyReport': true,
            'achievementUnlocks': true,
          },
        });
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

      // Create/update user profile in Firestore
      if (userCredential.user != null) {
        final userDoc =
            _firestore.collection('users').doc(userCredential.user!.uid);

        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          // New user - create profile
          await userDoc.set({
            'email': userCredential.user!.email ?? '',
            'displayName': userCredential.user!.displayName ?? '',
            'photoURL': userCredential.user!.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'totalAssessments': 0,
            'isAnonymous': false,
            'authProvider': 'google',
            'notificationPreferences': {
              'dailyReminder': true,
              'weeklyReport': true,
              'achievementUnlocks': true,
            },
          });
        } else {
          // Existing user - update last login
          await userDoc.update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }

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

        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            'email': user.email ?? appleCredential.email ?? '',
            'displayName': user.displayName ?? appleFullName,
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'totalAssessments': 0,
            'isAnonymous': false,
            'authProvider': 'apple',
            'notificationPreferences': {
              'dailyReminder': true,
              'weeklyReport': true,
              'achievementUnlocks': true,
            },
          });
        } else {
          await userDoc.update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
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

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

      await _deleteUserData(user.uid);
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

      await _deleteUserData(user.uid);
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

      await _deleteUserData(user.uid);
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

  /// Delete all Firestore data for a user
  static Future<void> _deleteUserData(String uid) async {
    final subCollections = ['assessments', 'feedback'];
    for (final sub in subCollections) {
      final snap =
          await _firestore.collection('users').doc(uid).collection(sub).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
    await _firestore.collection('users').doc(uid).delete();
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
  // CLOUD FIRESTORE - DATA BACKUP
  // ============================================================================

  /// Backup assessment to Firestore
  static Future<void> backupAssessment(
      Map<String, dynamic> assessmentData) async {
    final userId = getUserId();
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('assessments')
          .add({
        ...assessmentData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Assessment backed up to Firestore');
    } catch (e) {
      debugPrint('Failed to backup assessment: $e');
    }
  }

  /// Backup recommendation feedback to Firestore
  static Future<void> backupFeedback(Map<String, dynamic> feedbackData) async {
    final userId = getUserId();
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('feedback')
          .add({
        ...feedbackData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Feedback backed up to Firestore');
    } catch (e) {
      debugPrint('Failed to backup feedback: $e');
    }
  }

  /// Get user's assessment history from cloud
  static Future<List<Map<String, dynamic>>> getCloudAssessments() async {
    final userId = getUserId();
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('assessments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Failed to fetch cloud assessments: $e');
      return [];
    }
  }

  /// Sync local data to cloud (call after completing assessment)
  static Future<void> syncToCloud({
    required Map<String, dynamic> assessment,
    List<Map<String, dynamic>>? stressors,
    List<Map<String, dynamic>>? copingStrategies,
  }) async {
    final userId = getUserId();
    if (userId == null) return;

    try {
      // Create a batch write
      final batch = _firestore.batch();

      // User document reference
      final userDoc = _firestore.collection('users').doc(userId);

      // Update user profile
      batch.set(
        userDoc,
        {
          'lastAssessmentDate': FieldValue.serverTimestamp(),
          'totalAssessments': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      // Add assessment
      final assessmentDoc = userDoc.collection('assessments').doc();
      batch.set(assessmentDoc, {
        ...assessment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add stressors
      if (stressors != null) {
        for (var stressor in stressors) {
          final stressorDoc = assessmentDoc.collection('stressors').doc();
          batch.set(stressorDoc, stressor);
        }
      }

      // Add coping strategies
      if (copingStrategies != null) {
        for (var strategy in copingStrategies) {
          final strategyDoc =
              assessmentDoc.collection('coping_strategies').doc();
          batch.set(strategyDoc, strategy);
        }
      }

      await batch.commit();
      debugPrint('Data synced to cloud successfully');
    } catch (e) {
      debugPrint('Failed to sync data to cloud: $e');
    }
  }

  // ============================================================================
  // ANALYTICS & INSIGHTS
  // ============================================================================

  /// Save aggregated stats for research analysis
  static Future<void> saveResearchData({
    required String userId,
    required int pssScore,
    required String stressCategory,
    required int stressorCount,
    required int copingStrategyCount,
    required bool isCrisis,
  }) async {
    try {
      await _firestore.collection('research_analytics').add({
        'userId': userId,
        'pssScore': pssScore,
        'stressCategory': stressCategory,
        'stressorCount': stressorCount,
        'copingStrategyCount': copingStrategyCount,
        'isCrisis': isCrisis,
        'timestamp': FieldValue.serverTimestamp(),
        'country': 'Uganda/Kenya', // Can be made dynamic
      });
    } catch (e) {
      debugPrint('Failed to save research data: $e');
    }
  }
}
