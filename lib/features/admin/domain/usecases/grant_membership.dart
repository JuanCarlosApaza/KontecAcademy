import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/memberships_repository.dart';

/// Caso de uso: otorgar una membresía manual (activa con fechas).
class GrantMembership
    extends UseCase<(MembershipRecord?, Failure?), AdminGrantInput> {
  GrantMembership(this._repository);

  final MembershipsRepository _repository;

  @override
  Future<(MembershipRecord?, Failure?)> call(AdminGrantInput input) =>
      _repository.grant(input);
}
