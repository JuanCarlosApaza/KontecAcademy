import 'package:equatable/equatable.dart';

/// Datos para crear un usuario desde el panel admin
/// (`POST /admin/users`): auth + perfil + rol.
class NewAdminUser extends Equatable {
  const NewAdminUser({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    this.role = 'student',
  });

  final String email;
  final String password;
  final String fullName;
  final String? phone;

  /// 'admin' | 'student'
  final String role;

  @override
  List<Object?> get props => [email, password, fullName, phone, role];
}
