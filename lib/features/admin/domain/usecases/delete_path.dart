import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/paths_repository.dart';

/// Caso de uso: borra una ruta (`DELETE /admin/paths/:id`).
/// `false` = la ruta no existía (404).
class DeletePath extends UseCase<(bool, Failure?), String> {
  DeletePath(this._repository);

  final PathsAdminRepository _repository;

  @override
  Future<(bool, Failure?)> call(String id) => _repository.deletePath(id);
}
