import 'package:equatable/equatable.dart';

/// Sesión del panel: roles Y permisos del usuario (`GET /me`).
///
/// El backend devuelve los códigos ya resueltos (`users:view`,
/// `courses:create`, ...), con el bypass de `admin` incluido, así que
/// el front solo consulta sin replicar ninguna regla de negocio.
///
/// Fail-closed: sin sesión o si la llamada falla, llega vacío y
/// [hasAnyPermission] es false (nadie entra al panel por accidente).
class SessionAccess extends Equatable {
  const SessionAccess({
    this.roles = const [],
    this.permissions = const [],
  });

  /// Nombres de rol ('admin', 'teacher', 'student', ...).
  final List<String> roles;

  /// Códigos de permiso del panel ('users:view', ...).
  final List<String> permissions;

  /// ¿Tiene el permiso [code]?
  bool hasPermission(String code) => permissions.contains(code);

  /// ¿Puede entrar al panel? (cualquier permiso habilita una sección)
  bool get hasAnyPermission => permissions.isNotEmpty;

  /// ¿Es administrador? (rol `admin`: siempre con todos los permisos)
  bool get isAdmin => roles.contains('admin');

  @override
  List<Object?> get props => [roles, permissions];
}
