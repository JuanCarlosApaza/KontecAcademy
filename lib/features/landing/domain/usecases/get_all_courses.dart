import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/training_course.dart';
import '../repositories/course_repository.dart';

/// Caso de uso: obtener el catálogo completo de cursos
/// (pantalla de Capacitaciones).
class GetAllCourses
    extends UseCase<(List<TrainingCourse>, Failure?), NoParams> {
  GetAllCourses(this._repository);

  final CourseRepository _repository;

  @override
  Future<(List<TrainingCourse>, Failure?)> call(NoParams params) {
    return _repository.getAllCourses();
  }
}
