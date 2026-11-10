import '../../../../core/error/failures.dart';
import '../entities/course_curriculum.dart';

/// Contrato del aula de un curso. Lo implementa la capa `data`.
abstract interface class CurriculumRepository {
  /// Temario del curso para el usuario de la sesión.
  ///
  /// El backend aplica el gate de pago: sin aprobación las lecciones
  /// vienen con `contentUrl` en null. `(null, null)` = el curso no
  /// existe (no es un error del sistema).
  Future<(CourseCurriculum?, Failure?)> fetchCurriculum(String courseId);

  /// Marca/desmarca una lección como completada. Devuelve el `Failure`
  /// si algo falla (403 = el pago aún no está aprobado), o null si todo
  /// fue bien.
  Future<Failure?> setLessonProgress(
    String lessonId, {
    required bool completed,
  });
}
