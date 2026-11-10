import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/training_course.dart';
import '../repositories/course_repository.dart';

/// Caso de uso: curso por id para la pantalla de detalle.
///
/// `(null, null)` = no existe (404); [Failure] = error real.
class GetCourseById extends UseCase<(TrainingCourse?, Failure?), String> {
  GetCourseById(this._repository);

  final CourseRepository _repository;

  @override
  Future<(TrainingCourse?, Failure?)> call(String id) =>
      _repository.getCourseById(id);
}
