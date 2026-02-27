import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking user events/analytics in Firestore.
class UserEventModel {
  final String? id;
  final String eventType;
  final String screenName;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const UserEventModel({
    this.id,
    required this.eventType,
    required this.screenName,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventType': eventType,
      'screenName': screenName,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory UserEventModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserEventModel(
      id: docId,
      eventType: map['eventType'] ?? '',
      screenName: map['screenName'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
