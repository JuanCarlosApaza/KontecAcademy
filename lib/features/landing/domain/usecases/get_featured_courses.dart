import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/training_course.dart';
import '../repositories/course_repository.dart';

/// Caso de uso: obtener los cursos destacados del home.
class GetFeaturedCourses
    extends UseCase<(List<TrainingCourse>, Failure?), NoParams> {
  GetFeaturedCourses(this._repository);

  final CourseRepository _repository;

  @override
  Future<(List<TrainingCourse>, Failure?)> call(NoParams params) {
    return _repository.getFeaturedCourses();
  }
}
