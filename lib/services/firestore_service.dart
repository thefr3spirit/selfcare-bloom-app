import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/coping_strategy.dart';
import '../models/pss_assessment.dart';
import '../models/recommendation.dart';
import '../models/stressor.dart';
import '../models/user_profile.dart';

/// Firestore Cloud Sync Service
/// Provides offline-first cloud backup for all app data
/// Strategy: Write to Hive instantly → Sync to Firestore in background
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current authenticated user ID
  static String? get _userId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  static bool get isAuthenticated => _userId != null;

  // ============================================================================
  // USER PROFILE SYNC
  // ============================================================================

  /// Sync user profile to Firestore
  static Future<void> syncUserProfile(UserProfile profile) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Not authenticated - skipping profile sync');
      return;
    }

    try {
      await _firestore.collection('users').doc(_userId).set({
        'userId': profile.userId,
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender,
        'hasConsented': profile.hasConsented,
        'consentTimestamp': profile.consentTimestamp?.toIso8601String(),
        'createdAt': profile.createdAt.toIso8601String(),
        'lastSyncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Profile synced to Firestore');
    } catch (e) {
      debugPrint('❌ Profile sync failed: $e');
      // Don't throw - app should work offline
    }
  }

  /// Fetch user profile from Firestore
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('❌ Profile fetch failed: $e');
      return null;
    }
  }

  // ============================================================================
  // PSS ASSESSMENTS SYNC
  // ============================================================================

  /// Sync PSS assessment to Firestore
  static Future<void> syncAssessment(PSSAssessment assessment) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Not authenticated - skipping assessment sync');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('assessments')
          .doc(assessment.assessmentId)
          .set({
        'assessmentId': assessment.assessmentId,
        'date': assessment.date.toIso8601String(),
        'responses': assessment.responses,
        'totalScore': assessment.totalScore,
        'category': assessment.category,
        'isCrisis': assessment.isCrisis,
        'syncedAt': FieldValue.serverTimestamp(),
      });

      // Update user's total assessment count
      await _firestore.collection('users').doc(_userId).update({
        'totalAssessments': FieldValue.increment(1),
        'lastAssessmentDate': assessment.date.toIso8601String(),
      });

      debugPrint('✅ Assessment ${assessment.assessmentId} synced to Firestore');
    } catch (e) {
      debugPrint('❌ Assessment sync failed: $e');
      // Don't throw - app should work offline
    }
  }

  /// Fetch all assessments from Firestore
  static Future<List<Map<String, dynamic>>> fetchAssessments() async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('assessments')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Assessments fetch failed: $e');
      return [];
    }
  }

  // ============================================================================
  // STRESSORS SYNC
  // ============================================================================

  /// Sync stressors to Firestore
  static Future<void> syncStressors(
      List<Stressor> stressors, String assessmentId) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Not authenticated - skipping stressors sync');
      return;
    }

    try {
      // Use batch write for atomic operation
      final batch = _firestore.batch();

      for (var stressor in stressors) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('stressors')
            .doc('${assessmentId}_${stressor.type}');

        batch.set(docRef, {
          'assessmentId': assessmentId,
          'type': stressor.type,
          'severity': stressor.severity,
          'isSevere': stressor.isSevere,
          'recordedAt': stressor.recordedAt.toIso8601String(),
        });
      }

      await batch.commit();
      debugPrint('✅ ${stressors.length} stressors synced to Firestore');
    } catch (e) {
      debugPrint('❌ Stressors sync failed: $e');
    }
  }

  /// Fetch latest stressors from Firestore
  static Future<List<Map<String, dynamic>>> fetchStressors() async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('stressors')
          .orderBy('recordedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Stressors fetch failed: $e');
      return [];
    }
  }

  // ============================================================================
  // COPING STRATEGIES SYNC
  // ============================================================================

  /// Sync coping strategies to Firestore
  static Future<void> syncCopingStrategies(
      List<CopingStrategy> strategies, String assessmentId) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Not authenticated - skipping strategies sync');
      return;
    }

    try {
      final batch = _firestore.batch();

      for (var strategy in strategies) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('coping_strategies')
            .doc('${assessmentId}_${strategy.name}');

        batch.set(docRef, {
          'assessmentId': assessmentId,
          'name': strategy.name,
          'frequency': strategy.frequency,
          'effectivenessRating': strategy.effectivenessRating,
          'isPassive': strategy.isPassive,
          'recordedAt': strategy.recordedAt.toIso8601String(),
        });
      }

      await batch.commit();
      debugPrint('✅ ${strategies.length} coping strategies synced to Firestore');
    } catch (e) {
      debugPrint('❌ Coping strategies sync failed: $e');
    }
  }

  /// Fetch latest coping strategies from Firestore
  static Future<List<Map<String, dynamic>>> fetchCopingStrategies() async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('coping_strategies')
          .orderBy('recordedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Coping strategies fetch failed: $e');
      return [];
    }
  }

  // ============================================================================
  // RECOMMENDATIONS SYNC
  // ============================================================================

  /// Sync recommendations to Firestore
  static Future<void> syncRecommendations(
      List<Recommendation> recommendations) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Not authenticated - skipping recommendations sync');
      return;
    }

    try {
      final batch = _firestore.batch();

      for (var rec in recommendations) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('recommendations')
            .doc(rec.recommendationId);

        batch.set(docRef, {
          'recommendationId': rec.recommendationId,
          'type': rec.type,
          'title': rec.title,
          'message': rec.message,
          'actions': rec.actions,
          'evidenceBasis': rec.evidenceBasis,
          'resources': rec.resources,
          'priorityScore': rec.priorityScore,
          'generatedAt': rec.generatedAt.toIso8601String(),
          'isCrisisRecommendation': rec.isCrisisRecommendation,
          'isViewed': rec.isViewed,
        });
      }

      await batch.commit();
      debugPrint('✅ ${recommendations.length} recommendations synced to Firestore');
    } catch (e) {
      debugPrint('❌ Recommendations sync failed: $e');
    }
  }

  /// Fetch recommendations from Firestore
  static Future<List<Map<String, dynamic>>> fetchRecommendations() async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('recommendations')
          .orderBy('generatedAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Recommendations fetch failed: $e');
      return [];
    }
  }

  // ============================================================================
  // BULK SYNC & RESTORE
  // ============================================================================

  /// Perform initial sync on app startup/login
  /// Fetches cloud data stats and optionally triggers background sync
  static Future<void> performInitialSync() async {
    if (!isAuthenticated) {
      debugPrint('⏭️ Skipping initial sync - not authenticated');
      return;
    }

    try {
      debugPrint('🔄 Performing initial cloud sync...');

      // Get cloud data statistics
      final stats = await getCloudDataStats();
      debugPrint('📊 Cloud data: ${stats['assessments']} assessments, '
          '${stats['stressors']} stressors, '
          '${stats['strategies']} strategies, '
          '${stats['recommendations']} recommendations');

      // Note: For now, we prioritize local data (offline-first)
      // Future enhancement: Implement smart merge logic for multi-device sync
      debugPrint('✅ Initial sync complete - app ready');
    } catch (e) {
      debugPrint('⚠️ Initial sync failed (non-critical): $e');
      // App continues to work with local data
    }
  }

  /// Perform full cloud backup of all local data
  /// Call this periodically or when user triggers manual backup
  static Future<void> performFullBackup({
    required UserProfile? profile,
    required List<PSSAssessment> assessments,
    required List<Stressor> stressors,
    required List<CopingStrategy> strategies,
    required List<Recommendation> recommendations,
  }) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ Not authenticated - cannot perform backup');
      return;
    }

    debugPrint('🔄 Starting full cloud backup...');

    // Sync profile
    if (profile != null) {
      await syncUserProfile(profile);
    }

    // Sync assessments
    for (var assessment in assessments) {
      await syncAssessment(assessment);
    }

    // Sync stressors (link to latest assessment)
    if (stressors.isNotEmpty && assessments.isNotEmpty) {
      await syncStressors(stressors, assessments.first.assessmentId);
    }

    // Sync coping strategies (link to latest assessment)
    if (strategies.isNotEmpty && assessments.isNotEmpty) {
      await syncCopingStrategies(strategies, assessments.first.assessmentId);
    }

    // Sync recommendations
    await syncRecommendations(recommendations);

    debugPrint('✅ Full cloud backup complete');
  }

  /// Check if cloud has newer data than local
  /// Returns true if cloud data should be merged/downloaded
  static Future<bool> hasNewerCloudData(DateTime localLastSync) async {
    if (!isAuthenticated) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();

      if (!userDoc.exists) return false;

      final cloudLastSync = userDoc.data()?['lastSyncedAt'];
      if (cloudLastSync == null) return false;

      final cloudTimestamp =
          (cloudLastSync as Timestamp).toDate().millisecondsSinceEpoch;
      return cloudTimestamp > localLastSync.millisecondsSinceEpoch;
    } catch (e) {
      debugPrint('❌ Cloud data check failed: $e');
      return false;
    }
  }

  /// Get cloud data statistics
  static Future<Map<String, int>> getCloudDataStats() async {
    if (!isAuthenticated) {
      return {
        'assessments': 0,
        'stressors': 0,
        'strategies': 0,
        'recommendations': 0,
      };
    }

    try {
      final assessments = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('assessments')
          .count()
          .get();

      final stressors = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('stressors')
          .count()
          .get();

      final strategies = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('coping_strategies')
          .count()
          .get();

      final recommendations = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('recommendations')
          .count()
          .get();

      return {
        'assessments': assessments.count ?? 0,
        'stressors': stressors.count ?? 0,
        'strategies': strategies.count ?? 0,
        'recommendations': recommendations.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Cloud stats fetch failed: $e');
      return {
        'assessments': 0,
        'stressors': 0,
        'strategies': 0,
        'recommendations': 0,
      };
    }
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Test Firestore connectivity
  static Future<bool> testConnection() async {
    try {
      await _firestore
          .collection('_health_check')
          .doc('test')
          .set({'timestamp': FieldValue.serverTimestamp()});
      debugPrint('✅ Firestore connection successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore connection failed: $e');
      return false;
    }
  }

  /// Clear all user data from Firestore (for account deletion)
  static Future<void> deleteAllUserData() async {
    if (!isAuthenticated) return;

    try {
      debugPrint('🗑️ Deleting all cloud data for user $_userId...');

      // Delete subcollections
      final collections = [
        'assessments',
        'stressors',
        'coping_strategies',
        'recommendations',
      ];

      for (var collection in collections) {
        final snapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection(collection)
            .get();

        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Delete user document
      await _firestore.collection('users').doc(_userId).delete();

      debugPrint('✅ All cloud data deleted');
    } catch (e) {
      debugPrint('❌ Data deletion failed: $e');
      rethrow;
    }
  }
}
