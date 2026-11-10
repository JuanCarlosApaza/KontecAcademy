import 'package:equatable/equatable.dart';

/// Usuario autenticado (sesión de Supabase Auth).
///
/// Entidad pura del dominio: no conoce Supabase ni Flutter.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
  });

  /// UUID en `auth.users`.
  final String id;
  final String email;

  /// Nombre completo (viene de `user_metadata.full_name` al registrarse).
  final String? fullName;
  final String? avatarUrl;

  /// Nombre a mostrar: el completo si existe, si no el email.
  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty) ? email : fullName!;

  @override
  List<Object?> get props => [id, email, fullName, avatarUrl];
}
