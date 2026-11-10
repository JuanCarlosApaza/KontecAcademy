import '../../../../core/error/failures.dart';
import '../entities/roles_matrix.dart';

/// Contrato de la gestión de roles y permisos (`/admin/roles`).
///
/// Implementación (data): llama a la API Node con el JWT de Supabase;
/// el backend exige el permiso `roles:manage` en cada llamada.
abstract class RolesRepository {
  /// Matriz rol × permiso actual. Null + failure si falla.
  Future<(RolesMatrix?, Failure?)> getMatrix();

  /// Crea un rol. Devuelve null + failure si el nombre ya existe (400).
  Future<(RoleRecord?, Failure?)> createRole({
    required String name,
    required String description,
  });

  /// Reemplaza TODOS los permisos de un rol. Null = guardado.
  Future<Failure?> savePermissions({
    required String roleId,
    required List<String> codes,
  });

  /// Borra un rol. Null = borrado (400 base / 409 en uso → failure).
  Future<Failure?> deleteRole(String roleId);
}
