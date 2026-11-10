import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/membership_plan.dart';
import '../repositories/memberships_repository.dart';

/// Caso de uso: todos los planes de membresía (panel).
class ListPlans extends UseCase<(List<MembershipPlan>, Failure?), NoParams> {
  ListPlans(this._repository);

  final MembershipsRepository _repository;

  @override
  Future<(List<MembershipPlan>, Failure?)> call(NoParams params) =>
      _repository.listPlans();
}
