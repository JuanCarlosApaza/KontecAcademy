import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/memberships_repository.dart';

/// Caso de uso: borrar un plan de membresía (false = no existía).
class DeletePlan extends UseCase<(bool, Failure?), String> {
  DeletePlan(this._repository);

  final MembershipsRepository _repository;

  @override
  Future<(bool, Failure?)> call(String id) => _repository.deletePlan(id);
}
