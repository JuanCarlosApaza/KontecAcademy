import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/course_admin_repository.dart';

/// Caso de uso: borrar una lección y su progreso.
class DeleteLesson extends UseCase<(bool, Failure?), String> {
  DeleteLesson(this._repository);

  final CourseAdminRepository _repository;

  @override
  Future<(bool, Failure?)> call(String lessonId) {
    return _repository.deleteLesson(lessonId);
  }
}
