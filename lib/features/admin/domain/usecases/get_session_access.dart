import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/session_access.dart';
import '../repositories/admin_session_repository.dart';

/// Caso de uso: roles + permisos del usuario actual (`GET /me`).
///
/// Vacío si no hay sesión o la API falla (fail-closed).
class GetSessionAccess
    extends UseCase<(SessionAccess, Failure?), NoParams> {
  GetSessionAccess(this._repository);

  final AdminSessionRepository _repository;

  @override
  Future<(SessionAccess, Failure?)> call(NoParams params) =>
      _repository.getSession();
}
