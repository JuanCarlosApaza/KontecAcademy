import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sign_up_params.dart';
import '../entities/sign_up_result.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: crear cuenta con email, contraseña y nombre completo.
class SignUpWithEmail extends UseCase<(SignUpResult, Failure?), SignUpParams> {
  SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<(SignUpResult, Failure?)> call(SignUpParams params) {
    return _repository.signUpWithEmail(params);
  }
}
