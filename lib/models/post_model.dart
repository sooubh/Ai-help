import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a post in the Community Parent Forum.
class PostModel {
  final String? id;
  final String authorId;
  final String authorName;
  final String content;
  final List<String> likes;
  final DateTime createdAt;

  PostModel({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.likes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PostModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return PostModel(
      id: id ?? map['id'],
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Anonymous Parent',
      content: map['content'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? content,
    List<String>? likes,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
