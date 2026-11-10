import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/category.dart';
import '../category_slug.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: renombrar una categoría del catálogo.
class UpdateCategory
    extends UseCase<(Category, Failure?), UpdateCategoryParams> {
  UpdateCategory(this._repository);

  final AdminRepository _repository;

  @override
  Future<(Category, Failure?)> call(UpdateCategoryParams params) {
    final name = params.name.trim();
    final slug = categorySlugFor(name, params.slug);
    return _repository.updateCategory(id: params.id, name: name, slug: slug);
  }
}

class UpdateCategoryParams {
  const UpdateCategoryParams({
    required this.id,
    required this.name,
    this.slug = '',
  });

  final String id;
  final String name;
  final String slug;
}
