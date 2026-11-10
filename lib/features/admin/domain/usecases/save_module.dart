import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_curriculum.dart';
import '../entities/new_module.dart';
import '../repositories/course_admin_repository.dart';

/// Caso de uso: crear o editar un módulo del temario. El "mover" es un
/// PATCH con `orderIndex` (1-based dentro del curso).
class SaveModule extends UseCase<(AdminModule?, Failure?), NewModule> {
  SaveModule(this._repository);

  final CourseAdminRepository _repository;

  @override
  Future<(AdminModule?, Failure?)> call(NewModule params) {
    return _repository.saveModule(params);
  }
}
