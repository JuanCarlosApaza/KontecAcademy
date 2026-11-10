import 'package:equatable/equatable.dart';

import '../../domain/entities/student_record.dart';

/// DTO del estudiante del panel admin (`GET /admin/students`).
///
/// Único lugar del feature que conoce su JSON; la UI solo ve la
/// entidad [StudentRecord].
class StudentRecordModel extends Equatable {
  const StudentRecordModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.nationality,
    this.createdAt,
    this.enrolledCourses = 0,
    this.isActive = true,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? nationality;
  final DateTime? createdAt;
  final int enrolledCourses;
  final bool isActive;

  factory StudentRecordModel.fromJson(Map<String, dynamic> json) =>
      StudentRecordModel(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        nationality: json['nationality'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        enrolledCourses: (json['enrolledCourses'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );

  /// Traduce a entidad de dominio (mapper).
  StudentRecord toEntity() => StudentRecord(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    nationality: nationality,
    createdAt: createdAt,
    enrolledCourses: enrolledCourses,
    isActive: isActive,
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    nationality,
    createdAt,
    enrolledCourses,
    isActive,
  ];
}
