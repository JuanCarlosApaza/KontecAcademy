import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_curriculum.dart';
import '../repositories/curriculum_repository.dart';

/// Caso de uso: temario del curso (`/capacitaciones/:id/aula`).
///
/// El backend aplica el gate de pago; `(null, null)` = el curso no
/// existe (no es un error del sistema).
class GetCurriculum extends UseCase<(CourseCurriculum?, Failure?), String> {
  GetCurriculum(this._repository);

  final CurriculumRepository _repository;

  @override
  Future<(CourseCurriculum?, Failure?)> call(String courseId) {
    return _repository.fetchCurriculum(courseId);
  }
}
