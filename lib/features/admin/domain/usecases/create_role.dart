import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/roles_matrix.dart';
import '../repositories/roles_repository.dart';

/// Parámetros de CreateRole.
class CreateRoleParams {
  const CreateRoleParams({required this.name, this.description = ''});

  /// Nombre en minúsculas (`coordinador`); el backend lo valida.
  final String name;
  final String description;
}

/// Caso de uso: crea un rol (`POST /admin/roles`).
class CreateRole extends UseCase<(RoleRecord?, Failure?), CreateRoleParams> {
  CreateRole(this._repository);

  final RolesRepository _repository;

  @override
  Future<(RoleRecord?, Failure?)> call(CreateRoleParams params) =>
      _repository.createRole(
        name: params.name.trim(),
        description: params.description.trim(),
      );
}
