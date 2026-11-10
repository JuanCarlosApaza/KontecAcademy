import 'package:equatable/equatable.dart';

import '../../domain/entities/course_curriculum.dart';

/// DTO de una lección del aula (`GET /courses/:id/curriculum`).
class CurriculumLessonModel extends Equatable {
  const CurriculumLessonModel({
    required this.id,
    required this.title,
    required this.contentType,
    required this.order,
    required this.contentUrl,
    required this.isCompleted,
    this.contentText,
    this.attachmentUrl,
    this.attachmentName,
  });

  final String id;
  final String title;
  final String contentType;
  final int order;
  final String? contentUrl;
  final bool isCompleted;
  final String? contentText;
  final String? attachmentUrl;
  final String? attachmentName;

  factory CurriculumLessonModel.fromJson(Map<String, dynamic> json) =>
      CurriculumLessonModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        contentUrl: json['contentUrl'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        contentText: json['contentText'] as String?,
        attachmentUrl: json['attachmentUrl'] as String?,
        attachmentName: json['attachmentName'] as String?,
      );

  CurriculumLesson toEntity() => CurriculumLesson(
    id: id,
    title: title,
    contentType: contentType,
    order: order,
    contentUrl: contentUrl,
    isCompleted: isCompleted,
    contentText: contentText,
    attachmentUrl: attachmentUrl,
    attachmentName: attachmentName,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    contentType,
    order,
    contentUrl,
    isCompleted,
    contentText,
    attachmentUrl,
    attachmentName,
  ];
}

/// DTO de un módulo del aula.
class CurriculumModuleModel extends Equatable {
  const CurriculumModuleModel({
    required this.id,
    required this.title,
    required this.order,
    required this.lessons,
  });

  final String id;
  final String title;
  final int order;
  final List<CurriculumLessonModel> lessons;

  factory CurriculumModuleModel.fromJson(Map<String, dynamic> json) {
    final rows = json['lessons'] as List<dynamic>? ?? const [];
    return CurriculumModuleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      lessons: [
        for (final row in rows)
          CurriculumLessonModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  CurriculumModule toEntity() => CurriculumModule(
    id: id,
    title: title,
    order: order,
    lessons: [for (final lesson in lessons) lesson.toEntity()],
  );

  @override
  List<Object?> get props => [id, title, order, lessons];
}

/// DTO del temario completo (`GET /courses/:id/curriculum`).
class CourseCurriculumModel extends Equatable {
  const CourseCurriculumModel({
    required this.courseId,
    required this.courseTitle,
    required this.access,
    required this.modules,
    required this.totalLessons,
    required this.completedLessons,
  });

  final String courseId;
  final String courseTitle;
  final String access;
  final List<CurriculumModuleModel> modules;
  final int totalLessons;
  final int completedLessons;

  factory CourseCurriculumModel.fromJson(Map<String, dynamic> json) {
    final rows = json['modules'] as List<dynamic>? ?? const [];
    return CourseCurriculumModel(
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      access: json['access'] as String? ?? 'none',
      modules: [
        for (final row in rows)
          CurriculumModuleModel.fromJson(row as Map<String, dynamic>),
      ],
      totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completedLessons'] as num?)?.toInt() ?? 0,
    );
  }

  CourseCurriculum toEntity() => CourseCurriculum(
    courseId: courseId,
    courseTitle: courseTitle,
    access: access,
    modules: [for (final module in modules) module.toEntity()],
    totalLessons: totalLessons,
    completedLessons: completedLessons,
  );

  @override
  List<Object?> get props => [
    courseId,
    courseTitle,
    access,
    modules,
    totalLessons,
    completedLessons,
  ];
}
