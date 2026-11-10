import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/course_admin_repository.dart';

/// Caso de uso: borrar un módulo y todo su contenido (cascada).
class DeleteModule extends UseCase<(bool, Failure?), String> {
  DeleteModule(this._repository);

  final CourseAdminRepository _repository;

  @override
  Future<(bool, Failure?)> call(String moduleId) {
    return _repository.deleteModule(moduleId);
  }
}
