import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/created_user.dart';
import '../entities/new_admin_user.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: crear un usuario (auth + perfil + rol) desde el panel.
class CreateAdminUser
    extends UseCase<(CreatedUser, Failure?), CreateAdminUserParams> {
  CreateAdminUser(this._repository);

  final AdminRepository _repository;

  @override
  Future<(CreatedUser, Failure?)> call(CreateAdminUserParams params) {
    return _repository.createAdminUser(params.input);
  }
}

class CreateAdminUserParams {
  const CreateAdminUserParams({required this.input});

  final NewAdminUser input;
}
