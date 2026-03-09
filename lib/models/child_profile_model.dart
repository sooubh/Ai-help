import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive model representing a child's profile data.
/// Stored at: users/{userId}/children/{childId}
///
/// Contains all fields specified in PRD §7.2 and §17.1 for
/// AI-driven personalization and therapy recommendations.
class ChildProfileModel {
  final String? id;
  final String name;
  final int age;
  final String? gender;
  final List<String> conditions;
  final String communicationLevel;
  final List<String> behavioralConcerns;
  final List<String> sensoryIssues;
  final String motorSkillLevel;
  final List<String> learningAbilities;
  final List<String> parentGoals;
  final String currentTherapyStatus;
  final String? medicalNotes;
  final String? relationship; // e.g. Mother, Father
  final String? photoUrl;
  final List<String> completedModuleIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfileModel({
    this.id,
    required this.name,
    required this.age,
    this.gender,
    required this.conditions,
    required this.communicationLevel,
    required this.behavioralConcerns,
    required this.sensoryIssues,
    required this.motorSkillLevel,
    required this.learningAbilities,
    required this.parentGoals,
    required this.currentTherapyStatus,
    this.medicalNotes,
    this.relationship,
    this.photoUrl,
    this.completedModuleIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firestore document snapshot.
  factory ChildProfileModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ChildProfileModel(
      id: id ?? map['id'],
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'],
      conditions: List<String>.from(map['conditions'] ?? []),
      communicationLevel: map['communicationLevel'] ?? '',
      behavioralConcerns: List<String>.from(map['behavioralConcerns'] ?? []),
      sensoryIssues: List<String>.from(map['sensoryIssues'] ?? []),
      motorSkillLevel: map['motorSkillLevel'] ?? 'Unknown',
      learningAbilities: List<String>.from(map['learningAbilities'] ?? []),
      parentGoals: List<String>.from(map['parentGoals'] ?? []),
      currentTherapyStatus: map['currentTherapyStatus'] ?? 'None',
      medicalNotes: map['medicalNotes'],
      relationship: map['relationship'],
      photoUrl: map['photoUrl'],
      completedModuleIds: List<String>.from(map['completedModuleIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'conditions': conditions,
      'communicationLevel': communicationLevel,
      'behavioralConcerns': behavioralConcerns,
      'sensoryIssues': sensoryIssues,
      'motorSkillLevel': motorSkillLevel,
      'learningAbilities': learningAbilities,
      'parentGoals': parentGoals,
      'currentTherapyStatus': currentTherapyStatus,
      'medicalNotes': medicalNotes,
      'relationship': relationship,
      'photoUrl': photoUrl,
      'completedModuleIds': completedModuleIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields.
  ChildProfileModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    List<String>? conditions,
    String? communicationLevel,
    List<String>? behavioralConcerns,
    List<String>? sensoryIssues,
    String? motorSkillLevel,
    List<String>? learningAbilities,
    List<String>? parentGoals,
    String? currentTherapyStatus,
    String? medicalNotes,
    String? relationship,
    String? photoUrl,
    List<String>? completedModuleIds,
  }) {
    return ChildProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      conditions: conditions ?? this.conditions,
      communicationLevel: communicationLevel ?? this.communicationLevel,
      behavioralConcerns: behavioralConcerns ?? this.behavioralConcerns,
      sensoryIssues: sensoryIssues ?? this.sensoryIssues,
      motorSkillLevel: motorSkillLevel ?? this.motorSkillLevel,
      learningAbilities: learningAbilities ?? this.learningAbilities,
      parentGoals: parentGoals ?? this.parentGoals,
      currentTherapyStatus: currentTherapyStatus ?? this.currentTherapyStatus,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      relationship: relationship ?? this.relationship,
      photoUrl: photoUrl ?? this.photoUrl,
      completedModuleIds: completedModuleIds ?? this.completedModuleIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Summary string for AI context injection.
  String get summaryForAI =>
      'Name: $name, Age: $age, Conditions: ${conditions.join(", ")}, '
      'Communication: $communicationLevel, Motor: $motorSkillLevel';
}
