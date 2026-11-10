import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/roles_repository.dart';

/// Caso de uso: borra un rol (`DELETE /admin/roles/:id`).
///
/// Null = borrado; con failure el backend ya distinguió el caso
/// (rol base → 400, con usuarios → 409, no existe → 404).
class DeleteRole extends UseCase<Failure?, String> {
  DeleteRole(this._repository);

  final RolesRepository _repository;

  @override
  Future<Failure?> call(String roleId) => _repository.deleteRole(roleId);
}
