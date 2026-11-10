import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_curriculum.dart';
import '../repositories/course_admin_repository.dart';

/// Caso de uso: temario completo de un curso (sección "Temario").
class GetAdminCurriculum
    extends UseCase<(AdminCurriculum?, Failure?), String> {
  GetAdminCurriculum(this._repository);

  final CourseAdminRepository _repository;

  @override
  Future<(AdminCurriculum?, Failure?)> call(String params) {
    return _repository.fetchCurriculum(params);
  }
}
