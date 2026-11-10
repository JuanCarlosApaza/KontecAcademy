import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/roles_matrix.dart';
import '../repositories/roles_repository.dart';

/// Caso de uso: matriz rol × permiso (`GET /admin/roles`).
class GetRolesMatrix
    extends UseCase<(RolesMatrix?, Failure?), NoParams> {
  GetRolesMatrix(this._repository);

  final RolesRepository _repository;

  @override
  Future<(RolesMatrix?, Failure?)> call(NoParams params) =>
      _repository.getMatrix();
}
