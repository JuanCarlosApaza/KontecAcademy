import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../entities/new_course.dart';
import '../repositories/course_admin_repository.dart';

/// Caso de uso: crear un curso del catálogo (panel admin).
class CreateCourse extends UseCase<(TrainingCourse, Failure?), NewCourse> {
  CreateCourse(this._repository);

  final CourseAdminRepository _repository;

  @override
  Future<(TrainingCourse, Failure?)> call(NewCourse params) {
    return _repository.createCourse(params);
  }
}
