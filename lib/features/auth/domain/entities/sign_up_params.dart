import 'package:equatable/equatable.dart';

/// Parámetros y resultado de un registro con email + contraseña.
class SignUpParams extends Equatable {
  const SignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  final String email;
  final String password;
  final String fullName;

  /// Teléfono con prefijo internacional (ej: '+591 71234567').
  final String? phone;

  @override
  List<Object?> get props => [email, password, fullName, phone];
}
