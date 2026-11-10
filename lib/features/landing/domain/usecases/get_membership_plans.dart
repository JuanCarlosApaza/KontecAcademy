import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/membership_plan.dart';
import '../repositories/membership_plan_repository.dart';

/// Caso de uso: obtener los planes de membresía activos
/// (pantalla /membresias).
class GetMembershipPlans
    extends UseCase<(List<MembershipPlan>, Failure?), NoParams> {
  GetMembershipPlans(this._repository);

  final MembershipPlanRepository _repository;

  @override
  Future<(List<MembershipPlan>, Failure?)> call(NoParams params) {
    return _repository.getPlans();
  }
}
