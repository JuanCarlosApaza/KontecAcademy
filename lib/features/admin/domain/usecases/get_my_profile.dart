import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/student_profile.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: perfil PROPIO del usuario de la sesión
/// (`GET /me/profile`) — pantalla "Mi perfil" (sin permisos admin).
class GetMyProfile extends UseCase<(StudentProfile, Failure?), NoParams> {
  GetMyProfile(this._repository);

  final AdminRepository _repository;

  @override
  Future<(StudentProfile, Failure?)> call(NoParams params) =>
      _repository.getMyProfile();
}
