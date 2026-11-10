import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/membership_plan.dart';
import '../repositories/memberships_repository.dart';

/// Caso de uso: crear un plan de membresía (panel).
class CreatePlan
    extends UseCase<(MembershipPlan?, Failure?), AdminPlanInput> {
  CreatePlan(this._repository);

  final MembershipsRepository _repository;

  @override
  Future<(MembershipPlan?, Failure?)> call(AdminPlanInput input) =>
      _repository.createPlan(input);
}
