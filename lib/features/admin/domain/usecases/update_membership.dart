import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/memberships_repository.dart';

/// Parámetros de UpdateMembership (revocar / reactivar / fechas).
class UpdateMembershipParams {
  const UpdateMembershipParams({required this.id, required this.patch});

  final String id;
  final Map<String, dynamic> patch;
}

/// Caso de uso: actualizar estado/fechas de una membresía.
class UpdateMembership
    extends UseCase<(MembershipRecord?, Failure?), UpdateMembershipParams> {
  UpdateMembership(this._repository);

  final MembershipsRepository _repository;

  @override
  Future<(MembershipRecord?, Failure?)> call(UpdateMembershipParams params) =>
      _repository.updateMembership(params.id, params.patch);
}
