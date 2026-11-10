import '../../../../core/error/failures.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../entities/admin_curriculum.dart';
import '../entities/new_course.dart';
import '../entities/new_lesson.dart';
import '../entities/new_module.dart';

/// Contrato de escritura del catálogo (panel administrativo).
abstract interface class CourseAdminRepository {
  /// Crea el curso en la API y devuelve el curso ya persistido
  /// (o un [Failure] si algo sale mal).
  Future<(TrainingCourse, Failure?)> createCourse(NewCourse input);

  /// Actualiza un curso existente. El "eliminar" del panel es un cambio
  /// de estado (status 'inactive'): nunca se borra el registro.
  Future<(TrainingCourse, Failure?)> updateCourse(String id, NewCourse input);

  // ── TEMARIO (módulos + lecciones) ─────────────────────────────

  /// Temario completo del curso con todas sus URLs. `(null, null)` =
  /// el curso no existe (no es un error del sistema).
  Future<(AdminCurriculum?, Failure?)> fetchCurriculum(String courseId);

  /// Crea o edita un módulo (alta si `moduleId` es null).
  Future<(AdminModule?, Failure?)> saveModule(NewModule input);

  /// Borra el módulo y todo su contenido (cascada). false = no existía.
  Future<(bool, Failure?)> deleteModule(String moduleId);

  /// Crea o edita una lección (alta si `lessonId` es null).
  Future<(AdminLesson?, Failure?)> saveLesson(
    String moduleId,
    NewLesson input,
  );

  /// Borra la lección y su progreso. false = no existía.
  Future<(bool, Failure?)> deleteLesson(String lessonId);
}
