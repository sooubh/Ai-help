/// Represents a direct note/message from a Doctor to a Parent's Dashboard.
class GuidanceNoteModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String childId;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  GuidanceNoteModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.childId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'childId': childId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory GuidanceNoteModel.fromMap(Map<String, dynamic> map, String id) {
    return GuidanceNoteModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? 'Your Doctor',
      childId: map['childId'] ?? '',
      title: map['title'] ?? 'New Guidance Note',
      content: map['content'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
