import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: iniciar sesión con Google (OAuth por redirect).
class SignInWithGoogle
    extends UseCase<(AuthUser?, Failure?), SignInGoogleParams> {
  SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  Future<(AuthUser?, Failure?)> call(SignInGoogleParams params) {
    return _repository.signInWithGoogle(redirectTo: params.redirectTo);
  }
}

class SignInGoogleParams {
  const SignInGoogleParams({this.redirectTo});

  /// URL a la que Supabase devuelve al usuario tras autenticarse.
  final String? redirectTo;
}
