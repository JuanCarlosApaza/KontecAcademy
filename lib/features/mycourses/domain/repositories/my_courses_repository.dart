import '../entities/enrolled_course.dart';

/// Contrato de "Mis cursos" (dominio).
///
/// Implementación (data): llama a `GET /my/courses` con el JWT del
/// usuario; el backend devuelve las inscripciones con su estado.
abstract class MyCoursesRepository {
  /// Cursos inscritos del usuario de la sesión, con su estado.
  Future<List<EnrolledCourse>> fetchMyCourses();
}
