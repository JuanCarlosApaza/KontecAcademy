import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category.dart';
import '../repositories/course_repository.dart';

/// Caso de uso: obtener las categorías del catálogo (chips de filtro).
class GetCategories extends UseCase<(List<Category>, Failure?), NoParams> {
  GetCategories(this._repository);

  final CourseRepository _repository;

  @override
  Future<(List<Category>, Failure?)> call(NoParams params) {
    return _repository.getCategories();
  }
}
