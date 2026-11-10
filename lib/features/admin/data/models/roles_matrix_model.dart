import '../../domain/entities/roles_matrix.dart';

/// DTO de la respuesta de `GET /admin/roles`.
///
/// Único lugar del feature que conoce el JSON de la matriz; el dominio
/// solo ve `RolesMatrix` (roles + permisos + grants).
class RolesMatrixModel {
  const RolesMatrixModel(this.matrix);

  final RolesMatrix matrix;

  factory RolesMatrixModel.fromJson(Map<String, dynamic> json) {
    final grantsJson = json['grants'] as Map<String, dynamic>? ?? const {};

    return RolesMatrixModel(
      RolesMatrix(
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .map((row) => _roleFromJson(row as Map<String, dynamic>))
            .toList(),
        permissions: (json['permissions'] as List<dynamic>? ?? const [])
            .map((row) => _permissionFromJson(row as Map<String, dynamic>))
            .toList(),
        grants: grantsJson.map(
          (name, codes) => MapEntry(
            name,
            List<String>.from(codes as List<dynamic>? ?? const []),
          ),
        ),
      ),
    );
  }
}

RoleRecord _roleFromJson(Map<String, dynamic> json) => RoleRecord(
  id: json['id'] as String,
  name: json['name'] as String,
  description: (json['description'] as String?) ?? '',
  userCount: (json['userCount'] as num?)?.toInt() ?? 0,
  system: json['system'] as bool? ?? false,
);

PermissionDef _permissionFromJson(Map<String, dynamic> json) => PermissionDef(
  code: json['code'] as String,
  description: (json['description'] as String?) ?? '',
);
