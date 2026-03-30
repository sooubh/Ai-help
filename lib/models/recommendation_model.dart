import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class RecommendationModel {
  final String id;
  final String title;
  final String duration;
  final String objective;
  final String reason;
  final DateTime createdAt;
  final DateTime expiresAt;

  RecommendationModel({
    String? id,
    required this.title,
    required this.duration,
    required this.objective,
    required this.reason,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       expiresAt =
           expiresAt ??
           DateTime(
             DateTime.now().year,
             DateTime.now().month,
             DateTime.now().day + 1,
           );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'objective': objective,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory RecommendationModel.fromMap(Map<String, dynamic> map) {
    return RecommendationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      duration: map['duration'] ?? '',
      objective: map['objective'] ?? '',
      reason: map['reason'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      expiresAt:
          map['expiresAt'] != null
              ? (map['expiresAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory RecommendationModel.fromJson(String source) =>
      RecommendationModel.fromMap(json.decode(source));
}
