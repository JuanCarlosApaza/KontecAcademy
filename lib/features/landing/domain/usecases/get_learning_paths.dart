import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/learning_path.dart';
import '../repositories/learning_path_repository.dart';

/// Caso de uso: obtener las rutas de entrenamiento publicadas
/// (pantalla /rutas).
class GetLearningPaths
    extends UseCase<(List<LearningPath>, Failure?), NoParams> {
  GetLearningPaths(this._repository);

  final LearningPathRepository _repository;

  @override
  Future<(List<LearningPath>, Failure?)> call(NoParams params) {
    return _repository.getPaths();
  }
}
