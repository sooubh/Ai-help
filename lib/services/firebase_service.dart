import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/child_profile_model.dart';
import '../models/chat_message_model.dart';
import '../models/activity_log_model.dart';

/// Centralized Firebase service handling Auth, Firestore reads/writes.
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      // Update display name on Firebase Auth profile
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }

      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName?.trim(),
        role: 'parent',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    }
    return user;
  }

  /// Sign in with email & password.
  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update last login time
    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    return credential.user;
  }

  /// Sign in with Google. Returns null if user cancels the picker.
  Future<User?> signInWithGoogle() async {
    // Trigger the native Google Sign-In flow
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User cancelled

    // Obtain auth details from the request
    final googleAuth = await googleUser.authentication;

    // Create a credential for Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      // Create or update user document (merge so we don't lose existing data)
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // New user — create full profile
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          role: 'parent',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await userDoc.set(userModel.toMap());
      } else {
        // Existing user — just update last login
        await userDoc.update({
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }

    return user;
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out (also signs out of Google).
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Delete user account and all associated data.
  Future<void> deleteAccount() async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Delete child profiles subcollection
    final children = await _firestore
        .collection('users')
        .doc(uid)
        .collection('children')
        .get();
    for (final doc in children.docs) {
      await doc.reference.delete();
    }

    // Delete chats subcollection
    final chats = await _firestore
        .collection('users')
        .doc(uid)
        .collection('chats')
        .get();
    for (final doc in chats.docs) {
      await doc.reference.delete();
    }

    // Delete user document
    await _firestore.collection('users').doc(uid).delete();

    // Delete Firebase Auth account
    await currentUser?.delete();
  }

  // ─── User Profile ──────────────────────────────────────────

  /// Get the current user's profile data.
  Future<UserModel?> getUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Update user profile fields.
  Future<void> updateUserProfile(Map<String, dynamic> fields) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(uid).update(fields);
  }

  // ─── Child Profile ──────────────────────────────────────────────

  /// Save or update the child profile under the current user.
  Future<String> saveChildProfile(ChildProfileModel profile) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('children');

    if (profile.id != null) {
      // Update existing
      await collection.doc(profile.id).set(profile.toMap());
      return profile.id!;
    } else {
      // Create new
      final doc = await collection.add(profile.toMap());
      return doc.id;
    }
  }

  /// Get all child profiles for the current user.
  Future<List<ChildProfileModel>> getChildProfiles() async {
    final uid = currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('children')
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ChildProfileModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get a single child profile.
  Future<ChildProfileModel?> getChildProfile([String? childId]) async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    if (childId != null) {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return ChildProfileModel.fromMap(doc.data()!, doc.id);
    }

    // Return first child if no ID specified
    final profiles = await getChildProfiles();
    return profiles.isNotEmpty ? profiles.first : null;
  }

  // ─── Chat Messages ─────────────────────────────────────────

  /// Stream chat messages ordered by timestamp.
  Stream<List<ChatMessageModel>> getChatMessages([String? childId]) {
    final uid = currentUser?.uid;
    if (uid == null) return Stream.value([]);

    final path = childId != null
        ? _firestore
            .collection('users')
            .doc(uid)
            .collection('children')
            .doc(childId)
            .collection('chats')
        : _firestore
            .collection('users')
            .doc(uid)
            .collection('chats');

    return path
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Send a chat message (from user or AI).
  Future<void> sendChatMessage(ChatMessageModel message,
      [String? childId]) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final path = childId != null
        ? _firestore
            .collection('users')
            .doc(uid)
            .collection('children')
            .doc(childId)
            .collection('chats')
        : _firestore
            .collection('users')
            .doc(uid)
            .collection('chats');

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

    final snapshot = await _firestore
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

    final snapshot = await _firestore
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

  /// Get weekly stats: total activities, total minutes, current streak.
  Future<Map<String, dynamic>> getWeeklyStats() async {
    final uid = currentUser?.uid;
    if (uid == null) return {'count': 0, 'minutes': 0, 'streak': 0};

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .where('completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .orderBy('completedAt', descending: true)
        .get();

    final logs = snapshot.docs
        .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
        .toList();

    int totalSeconds = 0;
    for (final log in logs) {
      totalSeconds += log.durationSeconds;
    }

    // Calculate streak (consecutive days with activity)
    int streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);
    final allLogs = await getActivityLogs(limit: 100);
    final activeDays = <String>{};
    for (final log in allLogs) {
      activeDays.add(
          '${log.completedAt.year}-${log.completedAt.month}-${log.completedAt.day}');
    }

    while (activeDays
        .contains('${checkDate.year}-${checkDate.month}-${checkDate.day}')) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return {
      'count': logs.length,
      'minutes': (totalSeconds / 60).round(),
      'streak': streak,
    };
  }
}
