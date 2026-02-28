/// Represents a Healthcare Professional (Doctor/Therapist) in the system.
class DoctorModel {
  final String id;
  final String name;
  final String email;
  final String specialization;
  final String clinicName;
  final String? photoUrl;
  final String? phone;
  final String? bio;
  final List<String> assignedPatientIds;

  DoctorModel({
    required this.id,
    required this.name,
    required this.email,
    this.specialization = 'Pediatric Specialist',
    this.clinicName = 'CARE-AI Network Clinic',
    this.photoUrl,
    this.phone,
    this.bio,
    this.assignedPatientIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialization': specialization,
      'clinicName': clinicName,
      'photoUrl': photoUrl,
      'phone': phone,
      'bio': bio,
      'assignedPatientIds': assignedPatientIds,
      'role': 'doctor',
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map, String id) {
    return DoctorModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      specialization: map['specialization'] ?? 'Pediatric Specialist',
      clinicName: map['clinicName'] ?? 'CARE-AI Network Clinic',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      bio: map['bio'],
      assignedPatientIds: List<String>.from(map['assignedPatientIds'] ?? []),
    );
  }
}
