import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../entities/new_course.dart';
import '../repositories/course_admin_repository.dart';

/// Caso de uso: actualizar un curso existente del catálogo.
class UpdateCourse
    extends UseCase<(TrainingCourse, Failure?), UpdateCourseParams> {
  UpdateCourse(this._repository);

  final CourseAdminRepository _repository;

  @override
  Future<(TrainingCourse, Failure?)> call(UpdateCourseParams params) {
    return _repository.updateCourse(params.id, params.input);
  }
}

class UpdateCourseParams {
  const UpdateCourseParams({required this.id, required this.input});

  final String id;
  final NewCourse input;
}
