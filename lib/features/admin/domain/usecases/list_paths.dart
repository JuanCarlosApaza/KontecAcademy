import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/learning_path.dart';
import '../repositories/paths_repository.dart';

/// Caso de uso: listado de rutas del panel (`GET /admin/paths`).
class ListPaths
    extends UseCase<(List<LearningPath>, Failure?), NoParams> {
  ListPaths(this._repository);

  final PathsAdminRepository _repository;

  @override
  Future<(List<LearningPath>, Failure?)> call(NoParams params) =>
      _repository.listPaths();
}
