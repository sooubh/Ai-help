import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single therapy game session and the child's performance.
class GameSessionModel {
  final String? id;
  final String gameType; // e.g., 'memory_match', 'attention_focus'
  final String skillCategory; // e.g., 'Cognitive', 'Attention'
  final String difficultyLevel; // e.g., 'Easy', 'Medium', 'Hard'
  final int score;
  final int maxScore;
  final int totalMoves;
  final int durationSeconds;
  final DateTime completedAt;
  final Map<String, dynamic>? additionalMetrics;

  const GameSessionModel({
    this.id,
    required this.gameType,
    required this.skillCategory,
    required this.difficultyLevel,
    required this.score,
    required this.maxScore,
    required this.totalMoves,
    required this.durationSeconds,
    required this.completedAt,
    this.additionalMetrics,
  });

  Map<String, dynamic> toMap() {
    return {
      'gameType': gameType,
      'skillCategory': skillCategory,
      'difficultyLevel': difficultyLevel,
      'score': score,
      'maxScore': maxScore,
      'totalMoves': totalMoves,
      'durationSeconds': durationSeconds,
      'completedAt': Timestamp.fromDate(completedAt),
      'additionalMetrics': additionalMetrics,
    };
  }

  factory GameSessionModel.fromMap(Map<String, dynamic> map, String docId) {
    return GameSessionModel(
      id: docId,
      gameType: map['gameType'] ?? '',
      skillCategory: map['skillCategory'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 'Easy',
      score: map['score']?.toInt() ?? 0,
      maxScore: map['maxScore']?.toInt() ?? 0,
      totalMoves: map['totalMoves']?.toInt() ?? 0,
      durationSeconds: map['durationSeconds']?.toInt() ?? 0,
      completedAt:
          (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalMetrics: map['additionalMetrics'] as Map<String, dynamic>?,
    );
  }
}
