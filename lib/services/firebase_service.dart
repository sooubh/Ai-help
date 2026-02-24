import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/child_profile_model.dart';
import '../models/chat_message_model.dart';

/// Centralized Firebase service handling Auth, Firestore reads/writes.
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Auth ────────────────────────────────────────────────────────

  /// Current Firebase user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email & password, then save user doc to Firestore.
  Future<User?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        createdAt: DateTime.now(),
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
    return credential.user;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Child Profile ──────────────────────────────────────────────

  /// Save or update the child profile under the current user.
  Future<void> saveChildProfile(ChildProfileModel profile) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('childProfile')
        .doc('main')
        .set(profile.toMap());
  }

  /// Get the child profile for the current user.
  Future<ChildProfileModel?> getChildProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('childProfile')
        .doc('main')
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return ChildProfileModel.fromMap(doc.data()!);
  }

  // ─── Chat Messages ─────────────────────────────────────────────

  /// Stream chat messages ordered by timestamp.
  Stream<List<ChatMessageModel>> getChatMessages() {
    final uid = currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chats')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Send a chat message (from user or AI).
  Future<void> sendChatMessage(ChatMessageModel message) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('chats')
        .add(message.toMap());
  }
}
