import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/learning_path.dart';
import '../repositories/paths_repository.dart';

/// Parámetros de SavePathCourses.
class SavePathCoursesParams {
  const SavePathCoursesParams({required this.id, required this.courses});

  final String id;
  final List<PathCourseAssignment> courses;
}

/// Caso de uso: reemplaza TODOS los cursos de una ruta
/// (`PUT /admin/paths/:id/courses`). `(null, null)` = ruta inexistente;
/// con failure el backend ya distinguió el caso (curso no existe → 400).
class SavePathCourses
    extends UseCase<(LearningPath?, Failure?), SavePathCoursesParams> {
  SavePathCourses(this._repository);

  final PathsAdminRepository _repository;

  @override
  Future<(LearningPath?, Failure?)> call(SavePathCoursesParams params) =>
      _repository.setPathCourses(params.id, params.courses);
}
