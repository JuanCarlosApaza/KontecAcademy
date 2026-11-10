import '../../../../core/error/failures.dart';
import '../../../landing/domain/entities/learning_path.dart';

/// Datos para crear/editar una ruta (formulario del panel).
class AdminPathInput {
  const AdminPathInput({
    required this.title,
    this.slug,
    this.description = '',
    this.coverUrl,
    this.modality = 'asynchronous',
    this.durationHours,
    this.accessMonths = 12,
    this.discountPercent = 0,
    this.sortOrder = 0,
    this.isPublished = true,
  });

  final String title;
  final String? slug;
  final String description;
  final String? coverUrl;
  final String modality;
  final int? durationHours;
  final int accessMonths;

  /// % de rebaja (0-100) de la ruta sobre el total de sus cursos.
  final int discountPercent;

  final int sortOrder;
  final bool isPublished;
}

/// Curso elegido para la ruta (orden + nivel).
class PathCourseAssignment {
  const PathCourseAssignment({
    required this.courseId,
    this.level,
    this.sortOrder = 0,
  });

  final String courseId;
  final String? level;
  final int sortOrder;
}

/// Contrato del CRUD de rutas del panel admin.
///
/// Usa las MISMAS entidades que la feature pública ([LearningPath]) para
/// que la pantalla admin y la pública compartan widgets. Traduce
/// excepciones de datos en [Failure] (patrón de roles).
abstract interface class PathsAdminRepository {
  /// Todas las rutas (incluye borradores).
  Future<(List<LearningPath>, Failure?)> listPaths();

  Future<(LearningPath?, Failure?)> createPath(AdminPathInput input);

  /// Actualiza la cabecera; `(null, null)` = la ruta no existe (404).
  Future<(LearningPath?, Failure?)> updatePath(
    String id,
    AdminPathInput input,
  );

  /// Reemplaza los cursos; `(null, null)` = la ruta no existe (404).
  Future<(LearningPath?, Failure?)> setPathCourses(
    String id,
    List<PathCourseAssignment> courses,
  );

  /// Borra la ruta; `false` = no existía (404).
  Future<(bool, Failure?)> deletePath(String id);
}
