import 'package:equatable/equatable.dart';

import '../../domain/entities/course_participant.dart';

/// DTO de un participante (`GET /admin/courses/:id/participants`).
class CourseParticipantModel extends Equatable {
  const CourseParticipantModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.status,
    this.enrolledAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String status;
  final String? enrolledAt;

  factory CourseParticipantModel.fromJson(Map<String, dynamic> json) =>
      CourseParticipantModel(
        userId: json['userId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        status: json['status'] as String? ?? '',
        enrolledAt: json['enrolledAt'] as String?,
      );

  CourseParticipant toEntity() => CourseParticipant(
    userId: userId,
    fullName: fullName,
    email: email,
    phone: phone,
    status: status,
    enrolledAt: enrolledAt == null ? null : DateTime.tryParse(enrolledAt!),
  );

  @override
  List<Object?> get props => [
    userId,
    fullName,
    email,
    phone,
    status,
    enrolledAt,
  ];
}

/// DTO del envoltorio { courseId, courseTitle, participants }.
class CourseParticipantsModel extends Equatable {
  const CourseParticipantsModel({
    required this.courseId,
    required this.courseTitle,
    this.participants = const [],
  });

  final String courseId;
  final String courseTitle;
  final List<CourseParticipantModel> participants;

  factory CourseParticipantsModel.fromJson(Map<String, dynamic> json) {
    final rows = json['participants'] as List<dynamic>? ?? const [];
    return CourseParticipantsModel(
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      participants: rows
          .map(
            (row) =>
                CourseParticipantModel.fromJson(row as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  CourseParticipants toEntity() => CourseParticipants(
    courseId: courseId,
    courseTitle: courseTitle,
    participants: participants.map((m) => m.toEntity()).toList(),
  );

  @override
  List<Object?> get props => [courseId, courseTitle, participants];
}
