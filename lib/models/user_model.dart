import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a registered user (parent or doctor).
/// Stored at: users/{uid} or doctors/{uid}
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String role; // 'parent' or 'doctor'
  final String? photoUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.role = 'parent',
    this.photoUrl,
    this.fcmToken,
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isDoctor => role == 'doctor';
  bool get isParent => role == 'parent';

  /// Create from Firestore document snapshot.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      role: map['role'] ?? 'parent',
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// Create a copy with updated fields.
  UserModel copyWith({
    String? displayName,
    String? role,
    String? photoUrl,
    String? fcmToken,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
