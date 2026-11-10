import 'package:equatable/equatable.dart';

/// Rol del panel con el nº de usuarios que lo tienen asignado.
class RoleRecord extends Equatable {
  const RoleRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.userCount,
    required this.system,
  });

  final String id;
  final String name;
  final String description;

  /// Usuarios con este rol (0 = se puede borrar).
  final int userCount;

  /// Rol base del sistema (admin/teacher/student): no se borra.
  final bool system;

  @override
  List<Object?> get props => [id, name, description, userCount, system];
}

/// Fila del catálogo de permisos (`modulo:accion`).
class PermissionDef extends Equatable {
  const PermissionDef({required this.code, required this.description});

  final String code;
  final String description;

  /// Módulo (`users` de `users:view`): agrupa la matriz en la UI.
  String get module => code.split(':').first;

  /// Acción (`view` de `users:view`).
  String get action => code.split(':').last;

  @override
  List<Object?> get props => [code, description];
}

/// Matriz rol × permiso de GET /admin/roles.
class RolesMatrix extends Equatable {
  const RolesMatrix({
    required this.roles,
    required this.permissions,
    required this.grants,
  });

  final List<RoleRecord> roles;
  final List<PermissionDef> permissions;

  /// nombre de rol → códigos concedidos. El rol admin sale completo.
  final Map<String, List<String>> grants;

  /// ¿El rol [role] tiene el permiso [code]?
  bool isGranted(RoleRecord role, String code) =>
      grants[role.name]?.contains(code) ?? false;

  /// Códigos actuales de un rol (copia editable).
  Set<String> codesOf(RoleRecord role) =>
      Set<String>.of(grants[role.name] ?? const <String>[]);

  /// Permisos agrupados por módulo, en el orden del catálogo.
  Map<String, List<PermissionDef>> get byModule {
    final grouped = <String, List<PermissionDef>>{};
    for (final permission in permissions) {
      grouped.putIfAbsent(permission.module, () => []).add(permission);
    }
    return grouped;
  }

  @override
  List<Object?> get props => [roles, permissions, grants];
}
