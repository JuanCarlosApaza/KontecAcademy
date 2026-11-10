import 'package:equatable/equatable.dart';

/// DTO de la respuesta de `GET /me` (sesión actual).
///
/// Único lugar del feature que conoce el JSON de `/me`; el dominio solo
/// ve `SessionAccess` (roles + permisos ya resueltos por el backend).
class SessionRolesModel extends Equatable {
  const SessionRolesModel([this.roles = const [], this.permissions = const []]);

  /// Nombres de rol ('admin', 'teacher', 'student', ...).
  final List<String> roles;

  /// Códigos de permiso del panel ('users:view', ...).
  ///
  /// Parse tolerante: si el backend no lo manda (versión vieja), queda
  /// vacío → fail-closed, nadie pasa el guard de permisos.
  final List<String> permissions;

  factory SessionRolesModel.fromJson(Map<String, dynamic> json) =>
      SessionRolesModel(
        List<String>.from(json['roles'] as List<dynamic>? ?? const []),
        List<String>.from(json['permissions'] as List<dynamic>? ?? const []),
      );

  @override
  List<Object?> get props => [roles, permissions];
}
