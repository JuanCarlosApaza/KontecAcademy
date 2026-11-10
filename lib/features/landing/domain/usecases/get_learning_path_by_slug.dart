import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/learning_path.dart';
import '../repositories/learning_path_repository.dart';

/// Caso de uso: obtener una ruta por slug (pantalla /rutas/:slug).
class GetLearningPathBySlug
    extends UseCase<(LearningPath?, Failure?), String> {
  GetLearningPathBySlug(this._repository);

  final LearningPathRepository _repository;

  @override
  Future<(LearningPath?, Failure?)> call(String slug) {
    return _repository.getPathBySlug(slug);
  }
}
