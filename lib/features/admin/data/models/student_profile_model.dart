import 'package:equatable/equatable.dart';

import '../../domain/entities/student_profile.dart';

/// DTO de una inscripción dentro del perfil del estudiante.
class StudentEnrollmentModel extends Equatable {
  const StudentEnrollmentModel({
    required this.courseId,
    required this.title,
    required this.status,
    this.enrolledAt,
  });

  final String courseId;
  final String title;
  final String status;
  final String? enrolledAt;

  factory StudentEnrollmentModel.fromJson(Map<String, dynamic> json) =>
      StudentEnrollmentModel(
        courseId: json['courseId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? '',
        enrolledAt: json['enrolledAt'] as String?,
      );

  StudentEnrollment toEntity() => StudentEnrollment(
    courseId: courseId,
    title: title,
    status: status,
    enrolledAt: enrolledAt == null ? null : DateTime.tryParse(enrolledAt!),
  );

  @override
  List<Object?> get props => [courseId, title, status, enrolledAt];
}

/// DTO del perfil del estudiante (`GET /admin/students/:id`).
class StudentProfileModel extends Equatable {
  const StudentProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.nationality,
    this.createdAt,
    this.isActive = true,
    this.enrollments = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? nationality;
  final String? createdAt;
  final bool isActive;
  final List<StudentEnrollmentModel> enrollments;

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    final rows = json['enrollments'] as List<dynamic>? ?? const [];
    return StudentProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      nationality: json['nationality'] as String?,
      createdAt: json['createdAt'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      enrollments: rows
          .map(
            (row) => StudentEnrollmentModel.fromJson(row as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  StudentProfile toEntity() => StudentProfile(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    nationality: nationality,
    createdAt: createdAt == null ? null : DateTime.tryParse(createdAt!),
    isActive: isActive,
    enrollments: enrollments.map((m) => m.toEntity()).toList(),
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    nationality,
    createdAt,
    isActive,
    enrollments,
  ];
}
