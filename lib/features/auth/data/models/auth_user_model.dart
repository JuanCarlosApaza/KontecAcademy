import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/auth_user.dart';

/// Usuario de Supabase convertido a modelo (aquí se mapea el JSON real).
class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;

  factory AuthUserModel.fromSupabase(supabase.User? user) {
    if (user == null) {
      return const AuthUserModel(id: '', email: '');
    }
    final metadata = user.userMetadata ?? const {};
    final fullName = metadata['full_name'] ?? metadata['name'];
    final avatar = metadata['avatar_url'] ?? metadata['picture'];
    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName is String && fullName.trim().isNotEmpty
          ? fullName
          : null,
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
    );
  }

  /// Convierte a entidad del dominio. El id vacío = sin sesión.
  AuthUser? toEntity() => id.isEmpty
      ? null
      : AuthUser(
          id: id,
          email: email,
          fullName: fullName,
          avatarUrl: avatarUrl,
        );
}

/// Resultado crudo del registro (modelo de datos, no dominio).
class SignUpData {
  const SignUpData({this.user, required this.needsEmailConfirmation});

  final AuthUserModel? user;
  final bool needsEmailConfirmation;
}
