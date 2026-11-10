import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_curriculum.dart';

/// DTO de una lección del temario (`GET /admin/courses/:id/curriculum`).
class AdminLessonModel extends Equatable {
  const AdminLessonModel({
    required this.id,
    required this.title,
    required this.contentType,
    required this.orderIndex,
    required this.videoUrl,
    required this.zoomUrl,
    required this.driveUrl,
    this.contentText,
    this.attachmentUrl,
    this.attachmentName,
  });

  final String id;
  final String title;
  final String contentType;
  final int orderIndex;
  final String? videoUrl;
  final String? zoomUrl;
  final String? driveUrl;
  final String? contentText;
  final String? attachmentUrl;
  final String? attachmentName;

  factory AdminLessonModel.fromJson(Map<String, dynamic> json) =>
      AdminLessonModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        videoUrl: json['videoUrl'] as String?,
        zoomUrl: json['zoomUrl'] as String?,
        driveUrl: json['driveUrl'] as String?,
        contentText: json['contentText'] as String?,
        attachmentUrl: json['attachmentUrl'] as String?,
        attachmentName: json['attachmentName'] as String?,
      );

  AdminLesson toEntity() => AdminLesson(
    id: id,
    title: title,
    contentType: contentType,
    orderIndex: orderIndex,
    videoUrl: videoUrl,
    zoomUrl: zoomUrl,
    driveUrl: driveUrl,
    contentText: contentText,
    attachmentUrl: attachmentUrl,
    attachmentName: attachmentName,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    contentType,
    orderIndex,
    videoUrl,
    zoomUrl,
    driveUrl,
    contentText,
    attachmentUrl,
    attachmentName,
  ];
}

/// DTO de un módulo del temario (con sus lecciones anidadas).
class AdminModuleModel extends Equatable {
  const AdminModuleModel({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.lessons,
  });

  final String id;
  final String title;
  final int orderIndex;
  final List<AdminLessonModel> lessons;

  factory AdminModuleModel.fromJson(Map<String, dynamic> json) {
    final rows = json['lessons'] as List<dynamic>? ?? const [];
    return AdminModuleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      lessons: [
        for (final row in rows)
          AdminLessonModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  AdminModule toEntity() => AdminModule(
    id: id,
    title: title,
    orderIndex: orderIndex,
    lessons: [for (final lesson in lessons) lesson.toEntity()],
  );

  @override
  List<Object?> get props => [id, title, orderIndex, lessons];
}

/// DTO del temario completo del curso.
class AdminCurriculumModel extends Equatable {
  const AdminCurriculumModel({
    required this.courseId,
    required this.courseTitle,
    required this.modules,
  });

  final String courseId;
  final String courseTitle;
  final List<AdminModuleModel> modules;

  factory AdminCurriculumModel.fromJson(Map<String, dynamic> json) {
    final rows = json['modules'] as List<dynamic>? ?? const [];
    return AdminCurriculumModel(
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      modules: [
        for (final row in rows)
          AdminModuleModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  AdminCurriculum toEntity() => AdminCurriculum(
    courseId: courseId,
    courseTitle: courseTitle,
    modules: [for (final module in modules) module.toEntity()],
  );

  @override
  List<Object?> get props => [courseId, courseTitle, modules];
}
