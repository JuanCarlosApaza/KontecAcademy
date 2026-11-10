import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/membership_plan.dart';
import '../repositories/memberships_repository.dart';

/// Parámetros de UpdatePlan.
class UpdatePlanParams {
  const UpdatePlanParams({required this.id, required this.input});

  final String id;
  final AdminPlanInput input;
}

/// Caso de uso: editar un plan de membresía (null si no existe).
class UpdatePlan
    extends UseCase<(MembershipPlan?, Failure?), UpdatePlanParams> {
  UpdatePlan(this._repository);

  final MembershipsRepository _repository;

  @override
  Future<(MembershipPlan?, Failure?)> call(UpdatePlanParams params) =>
      _repository.updatePlan(params.id, params.input);
}
