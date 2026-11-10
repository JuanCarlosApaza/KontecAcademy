import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/category.dart';
import '../category_slug.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: crear una categoría del catálogo.
class CreateCategory
    extends UseCase<(Category, Failure?), CreateCategoryParams> {
  CreateCategory(this._repository);

  final AdminRepository _repository;

  @override
  Future<(Category, Failure?)> call(CreateCategoryParams params) {
    final name = params.name.trim();
    final slug = categorySlugFor(name, params.slug);
    return _repository.createCategory(name, slug);
  }
}

class CreateCategoryParams {
  const CreateCategoryParams({required this.name, this.slug = ''});

  final String name;
  final String slug;
}
