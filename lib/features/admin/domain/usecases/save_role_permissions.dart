import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/roles_repository.dart';

/// Parámetros de SaveRolePermissions.
class SaveRolePermissionsParams {
  const SaveRolePermissionsParams({required this.roleId, required this.codes});

  final String roleId;

  /// Códigos concedidos al rol (lista completa, no incremental).
  final List<String> codes;
}

/// Caso de uso: reemplaza los permisos de un rol
/// (`PUT /admin/roles/:id/permissions`).
///
/// Null = guardado; con failure el mensaje ya explica el rechazo
/// (rol `admin` inmutable, código desconocido, rol inexistente...).
class SaveRolePermissions extends UseCase<Failure?, SaveRolePermissionsParams> {
  SaveRolePermissions(this._repository);

  final RolesRepository _repository;

  @override
  Future<Failure?> call(SaveRolePermissionsParams params) =>
      _repository.savePermissions(
        roleId: params.roleId,
        codes: params.codes,
      );
}
