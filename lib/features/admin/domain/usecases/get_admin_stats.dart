import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_stats.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: KPIs del dashboard administrativo.
class GetAdminStats extends UseCase<(AdminStats, Failure?), NoParams> {
  GetAdminStats(this._repository);

  final AdminRepository _repository;

  @override
  Future<(AdminStats, Failure?)> call(NoParams params) =>
      _repository.getStats();
}
