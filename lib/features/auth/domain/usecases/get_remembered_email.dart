import '../../../../core/usecase/usecase.dart';
import '../repositories/remember_email_repository.dart';

/// Caso de uso: leer el correo guardado por el checkbox "Recuérdame".
class GetRememberedEmail extends UseCase<String?, NoParams> {
  GetRememberedEmail(this._repository);

  final RememberEmailRepository _repository;

  @override
  Future<String?> call(NoParams params) => _repository.getRememberedEmail();
}
