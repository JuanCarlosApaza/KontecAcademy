import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/student_profile.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: perfil de un estudiante + sus inscripciones
/// (pantalla de detalle del panel).
class GetStudentProfile extends UseCase<(StudentProfile, Failure?), String> {
  GetStudentProfile(this._repository);

  final AdminRepository _repository;

  @override
  Future<(StudentProfile, Failure?)> call(String id) =>
      _repository.getStudentProfile(id);
}
