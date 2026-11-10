import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../entities/training_course.dart';

/// Contrato de acceso al catálogo (cursos y categorías).
/// Hoy lo cumple un datasource remoto contra el server Node + Supabase.
abstract interface class CourseRepository {
  /// Cursos destacados del home, o un [Failure] si algo sale mal.
  Future<(List<TrainingCourse>, Failure?)> getFeaturedCourses();

  /// Catálogo completo (pantalla de Capacitaciones).
  Future<(List<TrainingCourse>, Failure?)> getAllCourses();

  /// Curso por id (pantalla de detalle).
  ///
  /// `(null, null)` = no existe (404); `Failure` = error real
  /// (red, servidor).
  Future<(TrainingCourse?, Failure?)> getCourseById(String id);

  /// Categorías del catálogo (chips de filtro).
  Future<(List<Category>, Failure?)> getCategories();
}
