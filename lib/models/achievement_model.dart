import 'package:flutter/material.dart';

/// Represents an unlockable achievement/badge for the child or parent.
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final IconData iconData;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconData,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory AchievementModel.fromMap(
    Map<String, dynamic> map,
    String id, {
    required IconData iconData,
  }) {
    return AchievementModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconData: iconData,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt:
          map['unlockedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['unlockedAt'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      // We don't save IconData to Firestore, it's mapped locally by ID
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
    };
  }

  AchievementModel copyWith({
    String? title,
    String? description,
    IconData? iconData,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconData: iconData ?? this.iconData,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
