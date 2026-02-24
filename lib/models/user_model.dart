import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a registered user.
class UserModel {
  final String uid;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.createdAt,
  });

  /// Create from Firestore document snapshot.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
