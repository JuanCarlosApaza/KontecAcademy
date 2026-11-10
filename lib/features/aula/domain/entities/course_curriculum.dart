import 'package:equatable/equatable.dart';

/// Lección del aula, con el contenido ya gateado por el backend
/// (`contentUrl` es null si el pago no está aprobado).
class CurriculumLesson extends Equatable {
  const CurriculumLesson({
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

  /// 'recorded' | 'live' | 'drive' | 'text' | 'file' | 'link'.
  final String contentType;
  final int order;

  /// Primera URL disponible (video → zoom → drive) o null sin acceso.
  final String? contentUrl;
  final bool isCompleted;

  /// Texto de la lección (tipo 'text'); null sin acceso.
  final String? contentText;

  /// Archivo o enlace adjunto (tipo 'file' | 'link'); null sin acceso.
  final String? attachmentUrl;
  final String? attachmentName;

  /// true = la lección tiene contenido publicado (cualquier tipo).
  bool get hasContent =>
      (contentUrl?.isNotEmpty ?? false) ||
      (contentText?.isNotEmpty ?? false) ||
      (attachmentUrl?.isNotEmpty ?? false);

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

/// Sección del temario con sus lecciones ordenadas.
class CurriculumModule extends Equatable {
  const CurriculumModule({
    required this.id,
    required this.title,
    required this.order,
    required this.lessons,
  });

  final String id;
  final String title;
  final int order;
  final List<CurriculumLesson> lessons;

  @override
  List<Object?> get props => [id, title, order, lessons];
}

/// Temario de un curso tal y como lo ve el estudiante.
///
/// `access` es el gate que calcula el backend desde su inscripción:
///  * `full`     → pago aprobado, puede ver el contenido.
///  * `pending`  → el pago sigue en verificación manual.
///  * `rejected` → el admin rechazó el pago.
///  * `none`     → sin sesión o sin inscripción.
class CourseCurriculum extends Equatable {
  const CourseCurriculum({
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
  final List<CurriculumModule> modules;
  final int totalLessons;
  final int completedLessons;

  /// true = el pago fue aprobado → puede avanzar en el curso.
  bool get hasAccess => access == 'full';
  bool get isPendingReview => access == 'pending';
  bool get isRejected => access == 'rejected';

  /// Avance del estudiante (0 sin lecciones, para no dividir entre 0).
  double get progress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  /// Lecciones del curso en orden plano (para navegar "siguiente").
  List<CurriculumLesson> get lessons => [
    for (final module in modules) ...module.lessons,
  ];

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
