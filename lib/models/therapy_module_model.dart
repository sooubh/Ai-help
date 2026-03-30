import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a therapy module / lesson.
/// Stored at: therapy_modules/{moduleId}
///
/// PRD §7.4: Therapy Modules & Lessons Library
class TherapyModuleModel {
  final String id;
  final String title;
  final String objective;
  final List<String> conditionTypes;
  final String ageRange;
  final String skillCategory;
  final int difficultyLevel; // 1-5
  final List<String> materials;
  final List<String> instructions;
  final int durationMinutes;
  final String? safetyNotes;
  final String? expectedOutcomes;
  final String? createdBy; // doctorUid or 'system'
  final bool isExpertApproved;
  final List<String> mediaUrls;
  final String? iconName;
  final DateTime createdAt;

  // ── Adaptive therapy fields ──
  final String activityType; // 'interactive', 'guided', 'video', 'game'
  final List<String> targetSkills; // e.g., ['eye_contact', 'turn_taking']
  final List<String> prerequisites; // module IDs that should be completed first
  final bool adaptiveDifficultyEnabled;

  TherapyModuleModel({
    required this.id,
    required this.title,
    required this.objective,
    required this.conditionTypes,
    required this.ageRange,
    required this.skillCategory,
    this.difficultyLevel = 1,
    required this.materials,
    required this.instructions,
    this.durationMinutes = 15,
    this.safetyNotes,
    this.expectedOutcomes,
    this.createdBy,
    this.isExpertApproved = false,
    this.mediaUrls = const [],
    this.iconName,
    this.activityType = 'interactive',
    this.targetSkills = const [],
    this.prerequisites = const [],
    this.adaptiveDifficultyEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TherapyModuleModel.fromMap(Map<String, dynamic> map, String id) {
    return TherapyModuleModel(
      id: id,
      title: map['title'] ?? '',
      objective: map['objective'] ?? '',
      conditionTypes: List<String>.from(map['conditionTypes'] ?? []),
      ageRange: map['ageRange'] ?? '0-18',
      skillCategory: map['skillCategory'] ?? 'General',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      materials: List<String>.from(map['materials'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      durationMinutes: map['durationMinutes'] ?? 15,
      safetyNotes: map['safetyNotes'],
      expectedOutcomes: map['expectedOutcomes'],
      createdBy: map['createdBy'],
      isExpertApproved: map['isExpertApproved'] ?? false,
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      iconName: map['iconName'],
      activityType: map['activityType'] ?? 'interactive',
      targetSkills: List<String>.from(map['targetSkills'] ?? []),
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      adaptiveDifficultyEnabled: map['adaptiveDifficultyEnabled'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'objective': objective,
      'conditionTypes': conditionTypes,
      'ageRange': ageRange,
      'skillCategory': skillCategory,
      'difficultyLevel': difficultyLevel,
      'materials': materials,
      'instructions': instructions,
      'durationMinutes': durationMinutes,
      'safetyNotes': safetyNotes,
      'expectedOutcomes': expectedOutcomes,
      'createdBy': createdBy,
      'isExpertApproved': isExpertApproved,
      'mediaUrls': mediaUrls,
      'iconName': iconName,
      'activityType': activityType,
      'targetSkills': targetSkills,
      'prerequisites': prerequisites,
      'adaptiveDifficultyEnabled': adaptiveDifficultyEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Difficulty label for UI display.
  String get difficultyLabel {
    switch (difficultyLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Moderate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Beginner';
    }
  }
}
