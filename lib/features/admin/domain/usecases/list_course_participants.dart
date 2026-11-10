import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_participant.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: participantes de un curso (sección "Participantes"
/// del panel), con el título del curso para el encabezado.
class ListCourseParticipants
    extends UseCase<(CourseParticipants, Failure?), String> {
  ListCourseParticipants(this._repository);

  final AdminRepository _repository;

  @override
  Future<(CourseParticipants, Failure?)> call(String courseId) =>
      _repository.getCourseParticipants(courseId);
}
