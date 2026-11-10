import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: iniciar sesión con email y contraseña.
class SignInWithEmail
    extends UseCase<(AuthUser?, Failure?), SignInWithEmailParams> {
  SignInWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<(AuthUser?, Failure?)> call(SignInWithEmailParams params) {
    return _repository.signInWithEmail(params.email.trim(), params.password);
  }
}

class SignInWithEmailParams {
  const SignInWithEmailParams({required this.email, required this.password});

  final String email;
  final String password;
}
