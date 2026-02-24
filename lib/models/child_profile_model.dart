import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a child's profile data.
/// Stored at: users/{userId}/childProfile/main
class ChildProfileModel {
  final String name;
  final int age;
  final String condition;
  final String communicationLevel;
  final List<String> challenges;
  final List<String> goals;
  final DateTime updatedAt;

  ChildProfileModel({
    required this.name,
    required this.age,
    required this.condition,
    required this.communicationLevel,
    required this.challenges,
    required this.goals,
    required this.updatedAt,
  });

  /// Create from Firestore document snapshot.
  factory ChildProfileModel.fromMap(Map<String, dynamic> map) {
    return ChildProfileModel(
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      condition: map['condition'] ?? '',
      communicationLevel: map['communicationLevel'] ?? '',
      challenges: List<String>.from(map['challenges'] ?? []),
      goals: List<String>.from(map['goals'] ?? []),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'condition': condition,
      'communicationLevel': communicationLevel,
      'challenges': challenges,
      'goals': goals,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
