import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a single completed therapy module session with rich performance data.
/// Stored at: users/{userId}/children/{childId}/therapy_sessions/{sessionId}
class TherapySessionModel {
  final String? id;
  final String moduleId;
  final String moduleTitle;
  final String skillCategory;
  final int difficultyLevel; // 1-5
  final int score;
  final int maxScore;
  final double accuracyPercent;
  final int timeSpentSeconds;
  final int stepsCompleted;
  final int totalSteps;
  final int engagementRating; // 1-5 derived from interactions
  final String? aiFeedback;
  final List<String> nextRecommendedModuleIds;
  final Map<String, dynamic>? performanceMetrics;
  final DateTime completedAt;

  const TherapySessionModel({
    this.id,
    required this.moduleId,
    required this.moduleTitle,
    required this.skillCategory,
    required this.difficultyLevel,
    required this.score,
    required this.maxScore,
    required this.accuracyPercent,
    required this.timeSpentSeconds,
    required this.stepsCompleted,
    required this.totalSteps,
    this.engagementRating = 3,
    this.aiFeedback,
    this.nextRecommendedModuleIds = const [],
    this.performanceMetrics,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'skillCategory': skillCategory,
      'difficultyLevel': difficultyLevel,
      'score': score,
      'maxScore': maxScore,
      'accuracyPercent': accuracyPercent,
      'timeSpentSeconds': timeSpentSeconds,
      'stepsCompleted': stepsCompleted,
      'totalSteps': totalSteps,
      'engagementRating': engagementRating,
      'aiFeedback': aiFeedback,
      'nextRecommendedModuleIds': nextRecommendedModuleIds,
      'performanceMetrics': performanceMetrics,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  factory TherapySessionModel.fromMap(Map<String, dynamic> map, String docId) {
    return TherapySessionModel(
      id: docId,
      moduleId: map['moduleId'] ?? '',
      moduleTitle: map['moduleTitle'] ?? '',
      skillCategory: map['skillCategory'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      score: map['score']?.toInt() ?? 0,
      maxScore: map['maxScore']?.toInt() ?? 0,
      accuracyPercent: (map['accuracyPercent'] ?? 0).toDouble(),
      timeSpentSeconds: map['timeSpentSeconds']?.toInt() ?? 0,
      stepsCompleted: map['stepsCompleted']?.toInt() ?? 0,
      totalSteps: map['totalSteps']?.toInt() ?? 0,
      engagementRating: map['engagementRating']?.toInt() ?? 3,
      aiFeedback: map['aiFeedback'],
      nextRecommendedModuleIds: List<String>.from(
        map['nextRecommendedModuleIds'] ?? [],
      ),
      performanceMetrics: map['performanceMetrics'] as Map<String, dynamic>?,
      completedAt:
          (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Percentage score for display.
  double get scorePercent => maxScore > 0 ? (score / maxScore * 100) : 0;

  /// Human-readable performance label.
  String get performanceLabel {
    final pct = scorePercent;
    if (pct >= 90) return 'Excellent';
    if (pct >= 75) return 'Great';
    if (pct >= 60) return 'Good';
    if (pct >= 40) return 'Needs Practice';
    return 'Keep Trying';
  }
}
