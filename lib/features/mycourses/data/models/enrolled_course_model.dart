import 'package:equatable/equatable.dart';

import '../../domain/entities/enrolled_course.dart';

/// DTO de un curso inscrito (`GET /my/courses`). Único lugar del
/// feature que conoce su JSON; la UI solo ve [EnrolledCourse].
class EnrolledCourseModel extends Equatable {
  const EnrolledCourseModel({
    required this.courseId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.modality,
    required this.status,
    required this.enrolledAt,
    required this.totalLessons,
    required this.completedLessons,
  });

  final String courseId;
  final String title;
  final String description;
  final String? imageUrl;
  final String modality;
  final String status;
  final String? enrolledAt;
  final int totalLessons;
  final int completedLessons;

  factory EnrolledCourseModel.fromJson(Map<String, dynamic> json) =>
      EnrolledCourseModel(
        courseId: json['courseId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        modality: json['modality'] as String? ?? '',
        status: json['status'] as String? ?? '',
        enrolledAt: json['enrolledAt'] as String?,
        totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
        completedLessons: (json['completedLessons'] as num?)?.toInt() ?? 0,
      );

  /// Traduce a entidad de dominio (mapper).
  EnrolledCourse toEntity() => EnrolledCourse(
    courseId: courseId,
    title: title,
    description: description,
    imageUrl: imageUrl,
    modality: modality,
    status: status,
    enrolledAt: enrolledAt == null ? null : DateTime.tryParse(enrolledAt!),
    totalLessons: totalLessons,
    completedLessons: completedLessons,
  );

  @override
  List<Object?> get props => [
    courseId,
    title,
    description,
    imageUrl,
    modality,
    status,
    enrolledAt,
    totalLessons,
    completedLessons,
  ];
}
