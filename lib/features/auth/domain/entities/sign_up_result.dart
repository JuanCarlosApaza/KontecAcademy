import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// Resultado de un registro con email + contraseña.
///
/// Cuando Supabase tiene la confirmación de email ACTIVADA, el registro
/// no devuelve sesión todavía: [emailConfirmationRequired] sale en true y
/// la UI debe pedir que revise el correo.
class SignUpResult extends Equatable {
  const SignUpResult({this.user, this.emailConfirmationRequired = false});

  /// Usuario recién creado (null si aún no hay sesión por confirmación).
  final AuthUser? user;

  /// true → revise tu correo para confirmar la cuenta.
  final bool emailConfirmationRequired;

  @override
  List<Object?> get props => [user, emailConfirmationRequired];
}
