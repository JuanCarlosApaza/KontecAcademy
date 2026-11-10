import 'package:equatable/equatable.dart';

/// Lección del temario tal y como la edita el panel admin: con TODAS
/// sus URLs de contenido (el aula del alumno solo ve la primera y con
/// el gate de pago).
class AdminLesson extends Equatable {
  const AdminLesson({
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

  /// 'recorded' | 'live' | 'drive' | 'text' | 'file' | 'link'.
  final String contentType;
  final int orderIndex;
  final String? videoUrl;
  final String? zoomUrl;
  final String? driveUrl;

  /// Texto de la lección (tipo 'text': bienvenida, guía, notas).
  final String? contentText;

  /// Archivo o enlace adjunto (tipo 'file' | 'link').
  final String? attachmentUrl;

  /// Nombre visible del adjunto (ej: "Syllabus.pdf").
  final String? attachmentName;

  /// true = la lección tiene algún contenido publicado.
  bool get hasContent =>
      (videoUrl?.isNotEmpty ?? false) ||
      (zoomUrl?.isNotEmpty ?? false) ||
      (driveUrl?.isNotEmpty ?? false) ||
      (contentText?.isNotEmpty ?? false) ||
      (attachmentUrl?.isNotEmpty ?? false);

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

/// Módulo del temario con sus lecciones ordenadas.
class AdminModule extends Equatable {
  const AdminModule({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.lessons,
  });

  final String id;
  final String title;
  final int orderIndex;
  final List<AdminLesson> lessons;

  AdminModule copyWith({String? title, List<AdminLesson>? lessons}) =>
      AdminModule(
        id: id,
        title: title ?? this.title,
        orderIndex: orderIndex,
        lessons: lessons ?? this.lessons,
      );

  @override
  List<Object?> get props => [id, title, orderIndex, lessons];
}

/// Temario completo de un curso (respuesta de
/// `GET /admin/courses/:id/curriculum`).
class AdminCurriculum extends Equatable {
  const AdminCurriculum({
    required this.courseId,
    required this.courseTitle,
    required this.modules,
  });

  final String courseId;
  final String courseTitle;
  final List<AdminModule> modules;

  /// Total de lecciones del curso (para el resumen del editor).
  int get totalLessons =>
      modules.fold(0, (sum, module) => sum + module.lessons.length);

  @override
  List<Object?> get props => [courseId, courseTitle, modules];
}
