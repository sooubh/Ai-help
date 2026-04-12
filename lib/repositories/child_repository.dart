import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/child_profile_model.dart';
import '../services/encryption_service.dart';

/// Repository for child profile CRUD with transparent field-level encryption.
class ChildRepository {
  ChildRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _encryptionService = encryptionService ?? EncryptionService.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;

  static const List<String> _sensitiveChildFields = [
    'name',
    'dateOfBirth',
    'diagnosis',
    'therapyNotes',
    'progressLogs',
  ];

  CollectionReference<Map<String, dynamic>> _childrenCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('children');
  }

  /// Saves a child profile after encrypting all configured sensitive fields.
  Future<String> saveChildProfile(ChildProfileModel profile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _encryptionService.initialize();
    final encryptedMap = _encryptionService.encryptMap(
      profile.toMap(),
      _sensitiveChildFields,
    );

    if (profile.id != null && profile.id!.isNotEmpty) {
      await _childrenCollection(uid).doc(profile.id).set(encryptedMap);
      return profile.id!;
    }

    final docRef = await _childrenCollection(uid).add(encryptedMap);
    return docRef.id;
  }

  /// Reads a child profile and decrypts configured sensitive fields.
  Future<ChildProfileModel?> getChildProfile(String childId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _encryptionService.initialize();
    final doc = await _childrenCollection(uid).doc(childId).get();
    if (!doc.exists || doc.data() == null) return null;

    final decryptedMap = _encryptionService.decryptMap(
      doc.data()!,
      _sensitiveChildFields,
    );
    return ChildProfileModel.fromMap(decryptedMap, doc.id);
  }

  /// Streams decrypted child profiles in real time.
  Stream<List<ChildProfileModel>> watchChildren() async* {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }

    await _encryptionService.initialize();
    yield* _childrenCollection(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final decryptedMap = _encryptionService.decryptMap(
              doc.data(),
              _sensitiveChildFields,
            );
            return ChildProfileModel.fromMap(decryptedMap, doc.id);
          }).toList(),
        );
  }
}
