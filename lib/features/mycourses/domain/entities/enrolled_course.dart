import 'package:equatable/equatable.dart';

/// Curso en el que el estudiante está inscrito (sección "Mis cursos").
class EnrolledCourse extends Equatable {
  const EnrolledCourse({
    required this.courseId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.modality,
    required this.status,
    required this.enrolledAt,
    this.totalLessons = 0,
    this.completedLessons = 0,
  });

  final String courseId;
  final String title;
  final String description;
  final String? imageUrl;

  /// Modalidad ('asynchronous' | 'synchronous' | 'hybrid' | ...).
  final String modality;

  /// Estado de la INSCRIPCIÓN: pending_payment | approved | rejected
  /// | finished | membership (acceso por membresía activa).
  final String status;

  /// Cuándo solicitó el curso por primera vez.
  final DateTime? enrolledAt;

  /// Total de lecciones del curso (0 sin acceso aprobado).
  final int totalLessons;

  /// Lecciones completadas por el estudiante (0 sin acceso aprobado).
  final int completedLessons;

  /// true = el pago fue aprobado por el admin → puede ENTRAR al curso.
  /// 'membership' también da acceso (membresía vigente).
  bool get hasAccess =>
      status == 'approved' || status == 'finished' || status == 'membership';

  /// true = el curso está disponible por MEMBRESÍA activa (badge).
  bool get isMembership => status == 'membership';

  /// true = solicitó el curso y su pago sigue en verificación manual.
  bool get isPendingReview => status == 'pending_payment';

  /// true = el admin le quitó el acceso (pago incompleto u otro motivo).
  bool get isRevoked => status == 'revoked';

  /// Avance 0..1 del curso (0 si no tiene lecciones).
  double get progress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

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
