import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_user_record.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: todos los usuarios + sus roles (sección "Usuarios").
class GetAdminUsers
    extends UseCase<(List<AdminUserRecord>, Failure?), NoParams> {
  GetAdminUsers(this._repository);

  final AdminRepository _repository;

  @override
  Future<(List<AdminUserRecord>, Failure?)> call(NoParams params) =>
      _repository.getUsers();
}
