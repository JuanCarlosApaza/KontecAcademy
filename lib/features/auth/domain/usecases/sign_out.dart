import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: cerrar la sesión actual.
class SignOut extends UseCase<Failure?, NoParams> {
  SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<Failure?> call(NoParams params) => _repository.signOut();
}
