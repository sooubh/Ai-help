import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/child_profile_model.dart';
import '../models/chat_message_model.dart';
import '../models/activity_log_model.dart';
import '../models/user_event_model.dart';
import '../models/recommendation_model.dart';
import '../models/game_session_model.dart';
import '../models/guidance_note_model.dart';
import '../models/doctor_model.dart';
import '../models/post_model.dart';
import '../models/therapy_session_model.dart';
import '../core/utils/app_logger.dart';
import '../core/errors/app_exceptions.dart';
import 'encryption_service.dart';
import 'cache/local_cache_service.dart';

/// Centralized Firebase service handling Auth, Firestore reads/writes.
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;
  
  // ─── In-Memory Cache (Optimization) ───────────────────────────
  UserModel? _cachedUser;
  List<ChildProfileModel>? _cachedChildProfiles;
  final Map<String, List<Map<String, dynamic>>> _cachedDailyPlans = {};

  /// Clear all cache (useful on logout or sign-in)
  void clearCache() {
    _cachedUser = null;
    _cachedChildProfiles = null;
    _cachedDailyPlans.clear();
  }

  /// Clear persisted per-user cache safely.
  /// Local cache may not be initialized in some test environments.
  Future<void> _clearPersistentCacheSafe() async {
    try {
      await LocalCacheService.instance.clearUserData();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  /// Centralized exception handler for Firebase routines
  Future<T> _guard<T>(
    Future<T> Function() operation, {
    String operationName = 'Firebase',
  }) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'Auth ($operationName)',
        e.message ?? 'Unknown Auth Error',
        e,
        StackTrace.current,
      );
      throw AuthException(e.message ?? 'Authentication failed', code: e.code);
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firestore ($operationName)',
        e.message ?? 'Unknown DB Error',
        e,
        StackTrace.current,
      );
      throw DataException(
        e.message ?? 'A database error occurred',
        originalError: e,
      );
    } catch (e, stack) {
      AppLogger.error(
        'FirebaseService ($operationName)',
        'Unexpected Error',
        e,
        stack,
      );
      throw DataException('An unexpected error occurred: $e', originalError: e);
    }
  }

  Future<void> _ensureEncryptionReady() => _encryptionService.initialize();

  Map<String, dynamic> _encryptParentProfileFields(Map<String, dynamic> data) {
    return _encryptionService.encryptMap(data, [
      'name',
      'displayName',
      'phone',
      'address',
    ]);
  }

  Map<String, dynamic> _decryptParentProfileFields(Map<String, dynamic> data) {
    return _encryptionService.decryptMap(data, [
      'name',
      'displayName',
      'phone',
      'address',
    ]);
  }

  Map<String, dynamic> _encryptChildProfileFields(Map<String, dynamic> data) {
    return _encryptionService.encryptMap(data, [
      'name',
      'dateOfBirth',
      'diagnosis',
      'therapyNotes',
      'progressLogs',
      'medicalNotes',
    ]);
  }

  Map<String, dynamic> _decryptChildProfileFields(Map<String, dynamic> data) {
    return _encryptionService.decryptMap(data, [
      'name',
      'dateOfBirth',
      'diagnosis',
      'therapyNotes',
      'progressLogs',
      'medicalNotes',
    ]);
  }

  Map<String, dynamic> _encryptDoctorNoteFields(Map<String, dynamic> data) {
    return _encryptionService.encryptMap(data, [
      'noteContent',
      'patientName',
      'content',
      'childName',
    ]);
  }

  Map<String, dynamic> _decryptDoctorNoteFields(Map<String, dynamic> data) {
    return _encryptionService.decryptMap(data, [
      'noteContent',
      'patientName',
      'content',
      'childName',
    ]);
  }

  // ─── Storage ──────────────────────────────────────────────────

  /// Uploads a file to Firebase Storage and returns the download URL.
  /// Enforces a 5MB size limit.
  Future<String?> uploadFile(File file, String path) async {
    try {
      // Check file size (5MB = 5 * 1024 * 1024 bytes)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size must be less than 5MB.');
      }

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (e.toString().contains('File size must be')) {
        rethrow;
      }
      return null;
    }
  }

  // ─── Auth ────────────────────────────────────────────────────

  /// Current Firebase user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email & password, then save user doc to Firestore.
  Future<User?> signUp(
    String email,
    String password, {
    String? displayName,
    String role = 'parent',
  }) async {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName.trim());
        }

        final userModel = UserModel(
          uid: user.uid,
          email: email.trim(),
          displayName: displayName?.trim(),
          role: role,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _ensureEncryptionReady();
        final encryptedUserMap = _encryptParentProfileFields(userModel.toMap());
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(encryptedUserMap);
      }
      return user;
    }, operationName: 'signUp');
  }

  /// Sign in with email & password.
  Future<User?> signIn(String email, String password) async {
    return _guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        clearCache();
        await _clearPersistentCacheSafe();
        await _ensureEncryptionReady();
        final encryptedSigninPayload = _encryptParentProfileFields({
          'email': credential.user!.email ?? email.trim(),
          'displayName': credential.user!.displayName,
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          ...encryptedSigninPayload,
        }, SetOptions(merge: true));
      }

      return credential.user;
    }, operationName: 'signIn');
  }

  /// Sign in with Google. Returns null if user cancels the picker.
  Future<User?> signInWithGoogle({String role = 'parent'}) async {
    return _guard(() async {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        clearCache();
        await _clearPersistentCacheSafe();
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            role: role,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _ensureEncryptionReady();
          await userDoc.set(_encryptParentProfileFields(userModel.toMap()));
        } else {
          await userDoc.update({
            'lastLoginAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      return user;
    }, operationName: 'signInWithGoogle');
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out (also signs out of Google).
  Future<void> signOut() async {
    clearCache();
    await _clearPersistentCacheSafe();
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Delete user account and all associated data.
  Future<void> deleteAccount() async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final userDoc = _firestore.collection('users').doc(uid);

    Future<void> deleteSubcollection(String subcollection) async {
      try {
        while (true) {
          final snapshot = await userDoc.collection(subcollection).limit(500).get();
          if (snapshot.docs.isEmpty) break;

          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        throw Exception('Failed deleting subcollection "$subcollection": $e');
      }
    }

    await deleteSubcollection('activity_logs');
    await deleteSubcollection('mood_entries');
    await deleteSubcollection('therapy_sessions');
    await deleteSubcollection('notifications');
    await deleteSubcollection('doctor_connections');
    await deleteSubcollection('progress_data');
    await deleteSubcollection('children');
    await deleteSubcollection('chats');

    // Note: This removes first-level documents in each listed subcollection.
    // For deeply nested subcollections, prefer a
    // Firebase Cloud Function with recursive delete for completeness.

    // Delete user document
    await userDoc.delete();

    // Delete Firebase Auth account
    await _auth.currentUser?.delete();
  }

  // ─── User Profile ──────────────────────────────────────────

  /// Get the current user's profile data.
  Future<UserModel?> getUserProfile() async {
    return _guard(() async {
      final uid = currentUser?.uid;
      if (uid == null) return null;
      if (_cachedUser != null) return _cachedUser;

      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists || doc.data() == null) return null;
        await _ensureEncryptionReady();
        final decrypted = _decryptParentProfileFields(doc.data()!);
        _cachedUser = UserModel.fromMap(decrypted, uid);
        return _cachedUser;
      } catch (e) {
        // Fallback to cache if network fails
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (!doc.exists || doc.data() == null) return null;
        await _ensureEncryptionReady();
        final decrypted = _decryptParentProfileFields(doc.data()!);
        return UserModel.fromMap(decrypted, uid);
      }
    }, operationName: 'getUserProfile');
  }

  /// Update user profile fields.
  Future<void> updateUserProfile(Map<String, dynamic> fields) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _ensureEncryptionReady();
    final encryptedFields = _encryptParentProfileFields(fields);
    await _firestore.collection('users').doc(uid).update(encryptedFields);
    _cachedUser = null; // Invalidate cache
  }

  // ─── Child Profile ──────────────────────────────────────────────

  /// Save or update the child profile under the current user.
  Future<String> saveChildProfile(ChildProfileModel profile) async {
    return _guard(() async {
      final uid = currentUser?.uid;
      if (uid == null) throw const AuthException('User not authenticated');

      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection('children');
      await _ensureEncryptionReady();
      final encryptedProfile = _encryptChildProfileFields(profile.toMap());

      if (profile.id != null) {
        await collection.doc(profile.id).set(encryptedProfile);
        _cachedChildProfiles = null; // Invalidate cache
        return profile.id!;
      } else {
        final doc = await collection.add(encryptedProfile);
        _cachedChildProfiles = null; // Invalidate cache
        return doc.id;
      }
    }, operationName: 'saveChildProfile');
  }

  /// Get all child profiles for the current user.
  Future<List<ChildProfileModel>> getChildProfiles() async {
    return _guard(() async {
      final uid = currentUser?.uid;
      if (uid == null) return [];
      if (_cachedChildProfiles != null) return _cachedChildProfiles!;

      try {
        final snapshot =
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('children')
                .orderBy('createdAt', descending: false)
                .get();
        await _ensureEncryptionReady();
        _cachedChildProfiles = snapshot.docs
            .map((doc) => ChildProfileModel.fromMap(
              _decryptChildProfileFields(doc.data()),
              doc.id,
            ))
            .toList();
        return _cachedChildProfiles!;
      } catch (e) {
        // Fallback to cache
        final snapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('children')
            .orderBy('createdAt', descending: false)
            .get(const GetOptions(source: Source.cache));
        await _ensureEncryptionReady();
        return snapshot.docs
            .map((doc) => ChildProfileModel.fromMap(
              _decryptChildProfileFields(doc.data()),
              doc.id,
            ))
            .toList();
      }
    }, operationName: 'getChildProfiles');
  }

  /// Get a single child profile.
  Future<ChildProfileModel?> getChildProfile([String? childId]) async {
    return _guard(() async {
      final uid = currentUser?.uid;
      if (uid == null) return null;

      if (childId != null) {
        try {
          final doc =
              await _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('children')
                  .doc(childId)
                  .get();
          if (!doc.exists || doc.data() == null) return null;
          await _ensureEncryptionReady();
          return ChildProfileModel.fromMap(
            _decryptChildProfileFields(doc.data()!),
            doc.id,
          );
        } catch (e) {
          final doc = await _firestore
              .collection('users')
              .doc(uid)
              .collection('children')
              .doc(childId)
              .get(const GetOptions(source: Source.cache));
          if (!doc.exists || doc.data() == null) return null;
          await _ensureEncryptionReady();
          return ChildProfileModel.fromMap(
            _decryptChildProfileFields(doc.data()!),
            doc.id,
          );
        }
      }

      final profiles = await getChildProfiles();
      return profiles.isNotEmpty ? profiles.first : null;
    }, operationName: 'getChildProfile');
  }

  // ─── Chat Messages ─────────────────────────────────────────

  /// Stream chat messages ordered by timestamp.
  Stream<List<ChatMessageModel>> getChatMessages([String? childId]) {
    final uid = currentUser?.uid;
    if (uid == null) return Stream.value([]);

    final path =
        childId != null
            ? _firestore
                .collection('users')
                .doc(uid)
                .collection('children')
                .doc(childId)
                .collection('chats')
            : _firestore.collection('users').doc(uid).collection('chats');

    return path
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Send a chat message (from user or AI).
  Future<void> sendChatMessage(
    ChatMessageModel message, [
    String? childId,
  ]) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final path =
        childId != null
            ? _firestore
                .collection('users')
                .doc(uid)
                .collection('children')
                .doc(childId)
                .collection('chats')
            : _firestore.collection('users').doc(uid).collection('chats');

    await path.add(message.toMap());
  }

  // ─── Bookmarks ─────────────────────────────────────────

  /// Bookmark a therapy activity by its ID.
  Future<void> bookmarkActivity(String activityId) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(activityId)
        .set({'bookmarkedAt': Timestamp.fromDate(DateTime.now())});
  }

  /// Remove a bookmarked activity.
  Future<void> unbookmarkActivity(String activityId) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(activityId)
        .delete();
  }

  /// Get all bookmarked activity IDs.
  Future<Set<String>> getBookmarkedIds() async {
    final uid = currentUser?.uid;
    if (uid == null) return {};

    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('bookmarks')
            .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  // ─── Activity Logging ──────────────────────────────────

  /// Log a completed activity session.
  Future<void> logActivity(ActivityLogModel log) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .add(log.toMap());
  }

  /// Get recent activity logs.
  Future<List<ActivityLogModel>> getActivityLogs({int limit = 20}) async {
    final uid = currentUser?.uid;
    if (uid == null) return [];

    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('activity_logs')
            .orderBy('completedAt', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs
        .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─── Daily Plan CRUD ───────────────────────────────────

  /// Save today's plan to Firestore.
  Future<void> saveDailyPlan(
    String date,
    List<Map<String, dynamic>> activities,
  ) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_plans')
        .doc(date)
        .set({
          'date': date,
          'activities': activities,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
    _cachedDailyPlans[date] = activities; // Update cache
  }

  /// Get daily plan for a given date.
  Future<List<Map<String, dynamic>>?> getDailyPlan(String date) async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    if (_cachedDailyPlans.containsKey(date)) return _cachedDailyPlans[date];

    final doc =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('daily_plans')
            .doc(date)
            .get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['activities'] == null) return null;
    
    _cachedDailyPlans[date] = List<Map<String, dynamic>>.from(data['activities']);
    return _cachedDailyPlans[date];
  }

  // ─── Milestones CRUD ───────────────────────────────────

  /// Save a milestone.
  Future<void> saveMilestone(Map<String, dynamic> milestone) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).collection('milestones').add({
      ...milestone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all milestones.
  Future<List<Map<String, dynamic>>> getMilestones() async {
    final uid = currentUser?.uid;
    if (uid == null) return [];

    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('milestones')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ─── Mood / Wellness ───────────────────────────────────

  /// Save a mood check-in.
  Future<void> saveMoodCheckIn(String mood, String? note) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('mood_checkins')
        .add({
          'mood': mood,
          'note': note,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  /// Get mood check-in history.
  Future<List<Map<String, dynamic>>> getMoodHistory({int limit = 14}) async {
    final uid = currentUser?.uid;
    if (uid == null) return [];

    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('mood_checkins')
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ─── Game Sessions ─────────────────────────────────────

  /// Log a completed therapy game session.
  Future<void> logGameSession(GameSessionModel session) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    // Save to the dedicated game_sessions collection
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('game_sessions')
        .add(session.toMap());

    // Also cast it as an activity log so it contributes to the weekly streak & charts
    final activityLog = ActivityLogModel(
      activityId: 'game_${session.gameType}',
      activityTitle: 'Game: ${session.gameType}',
      category: session.skillCategory,
      durationSeconds: session.durationSeconds,
      stepsCompleted: session.score,
      completedAt: session.completedAt,
    );
    await logActivity(activityLog);
  }

  // ─── Therapy Sessions ──────────────────────────────────

  /// Save a completed therapy session.
  Future<void> saveTherapySession(
    TherapySessionModel session, [
    String? childId,
  ]) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Save to child-specific subcollection if childId is provided
    if (childId != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .collection('therapy_sessions')
          .add(session.toMap());
    }

    // Also save to user-level collection for quick queries
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('therapy_sessions')
        .add(session.toMap());

    // Log as activity too for streak/chart compatibility
    final activityLog = ActivityLogModel(
      activityId: session.moduleId,
      activityTitle: session.moduleTitle,
      category: session.skillCategory,
      durationSeconds: session.timeSpentSeconds,
      stepsCompleted: session.stepsCompleted,
      completedAt: session.completedAt,
    );
    await logActivity(activityLog); // This already invalidates _cachedWeeklyStats
  }

  /// Get therapy sessions, optionally filtered by skill category.
  Future<List<TherapySessionModel>> getTherapySessions({
    int limit = 50,
    String? skillCategory,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return [];

    Query query = _firestore
        .collection('users')
        .doc(uid)
        .collection('therapy_sessions')
        .orderBy('completedAt', descending: true);

    if (skillCategory != null) {
      query = query.where('skillCategory', isEqualTo: skillCategory);
    }

    final snapshot = await query.limit(limit).get();

    return snapshot.docs
        .map(
          (doc) => TherapySessionModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  /// Get the set of module IDs that have been completed at least once.
  Future<Set<String>> getCompletedModuleIds([String? childId]) async {
    final uid = currentUser?.uid;
    if (uid == null) return {};

    if (childId != null) {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .get();
      if (doc.exists && doc.data()!.containsKey('completedModuleIds')) {
        final list = List<String>.from(doc.data()!['completedModuleIds'] ?? []);
        return list.toSet();
      }
    }
    return {};
  }

  // ─── User Event Tracking ───────────────────────────────

  /// Track a user event (screen view, feature tap, etc.).
  Future<void> saveUserEvent(UserEventModel event) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    // Fire-and-forget for performance
    _firestore
        .collection('users')
        .doc(uid)
        .collection('events')
        .add(event.toMap());
  }
  // ─── AI Recommendations Caching ──────────────────────────

  /// Fetch cached daily recommendations if valid.
  Future<List<RecommendationModel>?> getDailyRecommendations(
    String childId,
  ) async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('children')
              .doc(childId)
              .collection('recommendations')
              .doc('daily')
              .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        // Cache expired
        return null;
      }

      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      return items.map((e) => RecommendationModel.fromMap(e)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Save newly generated daily recommendations.
  Future<void> saveRecommendations(
    String childId,
    List<RecommendationModel> recommendations,
  ) async {
    final uid = currentUser?.uid;
    if (uid == null || recommendations.isEmpty) return;

    try {
      final expiresAt = recommendations.first.expiresAt;
      final itemsMap = recommendations.map((r) => r.toMap()).toList();

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .collection('recommendations')
          .doc('daily')
          .set({
            'expiresAt': Timestamp.fromDate(expiresAt),
            'items': itemsMap,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }
  // ─── Community Posts ──────────────────────────────────────

  /// Stream of community posts, ordered by latest.
  Stream<List<PostModel>> getCommunityPosts() {
    return _firestore
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PostModel.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Create a new community post.
  Future<void> createPost(String content, String authorName) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final post = PostModel(
      authorId: uid,
      authorName: authorName,
      content: content,
      likes: [],
    );

    await _firestore.collection('community_posts').add(post.toMap());
  }

  /// Toggle like status for a community post.
  Future<void> toggleLikePost(String postId) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore.collection('community_posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
      if (likes.contains(uid)) {
        likes.remove(uid);
      } else {
        likes.add(uid);
      }

      transaction.update(docRef, {'likes': likes});
    });
  }

  // ─── Achievements ──────────────────────────────────────────

  /// Get user's unlocked achievements IDs.
  Stream<List<String>> watchUnlockedAchievementIds() {
    final uid = currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Unlock a specific achievement.
  Future<void> unlockAchievement(String achievementId) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .doc(achievementId)
        .set({
          'unlockedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // ─── Doctor / Therapist Operations ────────────────────────

  /// Sends a direct guidance note from the doctor to the parent's dashboard.
  Future<void> sendGuidanceNote(GuidanceNoteModel note) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Doctor not authenticated');
    await _ensureEncryptionReady();
    final encryptedNote = _encryptDoctorNoteFields(note.toMap());

    await _firestore
        .collection('guidance_notes')
        .doc(note.id)
        .set(encryptedNote);
  }

  /// Appends a new activity directly to a child's assigned tasks queue.
  Future<void> assignActivityToChild(
    String parentUid,
    String childId,
    Map<String, dynamic> activity,
  ) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Doctor not authenticated');

    final docRef = _firestore
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId);

    await docRef.set({
      'assigned_tasks': FieldValue.arrayUnion([activity]),
    }, SetOptions(merge: true));
  }

  /// Retrieves guidance notes addressed to a specific child
  Stream<List<GuidanceNoteModel>> watchGuidanceNotes(String childId) {
    return _firestore
        .collection('guidance_notes')
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => GuidanceNoteModel.fromMap(
                    _decryptDoctorNoteFields(doc.data()),
                    doc.id,
                  ))
                  .toList(),
        );
  }

  /// Marks a guidance note as read
  Future<void> markGuidanceNoteRead(String noteId) async {
    await _firestore.collection('guidance_notes').doc(noteId).update({
      'isRead': true,
    });
  }

  // ─── Doctor Portal Queries ────────────────────────────────

  /// Fetch pending patient connection requests.
  Future<List<Map<String, dynamic>>> getDoctorRequests() async {
    final uid = currentUser?.uid;
    if (uid == null) return [];

    final snapshot =
        await _firestore
            .collection('doctor_requests')
            .where('doctorId', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['requestId'] = doc.id;
      return data;
    }).toList();
  }

  /// Respond to a patient connection request.
  Future<void> respondToDoctorRequest(String requestId, bool approve) async {
    final status = approve ? 'approved' : 'declined';
    final requestRef = _firestore.collection('doctor_requests').doc(requestId);
    final requestSnap = await requestRef.get();
    if (!requestSnap.exists || requestSnap.data() == null) {
      throw Exception('Doctor request not found');
    }

    final requestData = requestSnap.data()!;
    String? firstNonEmptyString(List<String> keys) {
      for (final key in keys) {
        final value = requestData[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return null;
    }

    final doctorId = firstNonEmptyString(['doctorId']) ?? '';
    // Support legacy request payloads while we standardize to `patientUid`.
    final patientUid =
        firstNonEmptyString(['patientUid', 'parentUid', 'userId']) ?? '';
    if (approve && (doctorId.isEmpty || patientUid.isEmpty)) {
      throw Exception('Approved request missing doctorId or patientUid');
    }

    final batch = _firestore.batch();
    batch.update(requestRef, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (approve) {
      final doctorRef = _firestore.collection('doctors').doc(doctorId);
      batch.set(doctorRef, {
        'patientIds': FieldValue.arrayUnion([patientUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Fetch the current user's profile as a DoctorModel.
  Future<DoctorModel?> getDoctorProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    await _ensureEncryptionReady();
    final decrypted = _decryptParentProfileFields(doc.data()!);
    return DoctorModel.fromMap(decrypted, uid);
  }

  /// Updates or creates the doctor's profile.
  Future<void> saveDoctorProfile(DoctorModel profile) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Doctor not authenticated');
    await _ensureEncryptionReady();
    final encrypted = _encryptParentProfileFields(profile.toMap());

    await _firestore
        .collection('users')
        .doc(uid)
        .set(encrypted, SetOptions(merge: true));
  }

  /// Fetch all parent users and their children to build the doctor's patient list.
  /// Returns a list of maps, each containing the parent info and child profile.
  Future<List<Map<String, dynamic>>> getDoctorPatients() async {
    const int firestoreWhereInLimit = 30;
    final uid = currentUser?.uid;
    if (uid == null) return [];

    final doctorDoc = await _firestore.collection('doctors').doc(uid).get();
    final rawPatientIds = doctorDoc.data()?['patientIds'];
    final patientIds =
        rawPatientIds is List
            ? rawPatientIds
                .whereType<String>()
                .map((id) => id.trim())
                .where((id) => id.isNotEmpty)
                .toList()
            : <String>[];
    if (patientIds.isEmpty) return [];

    List<List<String>> chunkList(List<String> items, int chunkSize) {
      final chunks = <List<String>>[];
      for (var i = 0; i < items.length; i += chunkSize) {
        final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
        chunks.add(items.sublist(i, end));
      }
      return chunks;
    }

    final idChunks = chunkList(patientIds, firestoreWhereInLimit);
    final parentSnapshots = await Future.wait(
      idChunks.map(
        (chunk) => _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get(),
      ),
    );

    final parentDocs = parentSnapshots.expand((snapshot) => snapshot.docs).toList();
    final patients = <Map<String, dynamic>>[];
    await _ensureEncryptionReady();

    final childrenSnapshots = await Future.wait(
      parentDocs.map(
        (parentDoc) => _firestore
            .collection('users')
            .doc(parentDoc.id)
            .collection('children')
            .get(),
      ),
    );

    for (var i = 0; i < parentDocs.length; i++) {
      final parentDoc = parentDocs[i];
      final parentData = _decryptParentProfileFields(parentDoc.data());
      final parentUid = parentDoc.id;
      final childrenSnapshot = childrenSnapshots[i];

      for (final childDoc in childrenSnapshot.docs) {
        final childData = _decryptChildProfileFields(childDoc.data());
        patients.add({
          'parentUid': parentUid,
          'parentName': parentData['displayName'] ?? 'Parent',
          'parentEmail': parentData['email'] ?? '',
          'childId': childDoc.id,
          'childName': childData['name'] ?? 'Unknown Child',
          'childAge': childData['age'] ?? 0,
          'childGender': childData['gender'] ?? '',
          'conditions': List<String>.from(childData['conditions'] ?? []),
          'communicationLevel': childData['communicationLevel'] ?? 'Unknown',
          'currentTherapyStatus':
              childData['currentTherapyStatus'] ?? 'Unknown',
          'createdAt': childData['createdAt'],
        });
      }
    }

    return patients;
  }

  /// Fetch activity logs for a specific parent's child (used by doctor to view patient progress).
  Future<List<ActivityLogModel>> getPatientActivityLogs(
    String parentUid, {
    int limit = 20,
  }) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(parentUid)
            .collection('activity_logs')
            .orderBy('completedAt', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs
        .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Count total guidance notes sent by the current doctor.
  Future<int> getDoctorNotesCount() async {
    final uid = currentUser?.uid;
    if (uid == null) return 0;

    final snapshot =
        await _firestore
            .collection('guidance_notes')
            .where('doctorId', isEqualTo: uid)
            .get();
    return snapshot.docs.length;
  }
}
