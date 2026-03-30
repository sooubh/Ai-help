import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a single chat message.
/// Stored at: users/{userId}/chats/{chatId}
class ChatMessageModel {
  final String id;
  final String message;
  final String sender; // 'user' or 'ai'
  final DateTime timestamp;
  final String? imagePath;

  ChatMessageModel({
    required this.id,
    required this.message,
    required this.sender,
    required this.timestamp,
    this.imagePath,
  });

  bool get isUser => sender == 'user';

  /// Create from Firestore document snapshot.
  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      message: map['message'] ?? '',
      sender: map['sender'] ?? 'user',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imagePath: map['imagePath'],
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'sender': sender,
      'timestamp': Timestamp.fromDate(timestamp),
      if (imagePath != null) 'imagePath': imagePath,
    };
  }
}
