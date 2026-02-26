import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/child_profile_model.dart';
import '../models/chat_message_model.dart';

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

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out.
  Future<void> signOut() async {
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
}
