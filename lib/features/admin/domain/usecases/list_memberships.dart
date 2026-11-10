import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/memberships_repository.dart';

/// Caso de uso: listado de membresías (panel).
class ListMemberships
    extends UseCase<(List<MembershipRecord>, Failure?), NoParams> {
  ListMemberships(this._repository);

  final MembershipsRepository _repository;

  @override
  Future<(List<MembershipRecord>, Failure?)> call(NoParams params) =>
      _repository.listMemberships();
}
