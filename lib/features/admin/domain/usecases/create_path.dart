import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/learning_path.dart';
import '../repositories/paths_repository.dart';

/// Caso de uso: crea una ruta (`POST /admin/paths`).
class CreatePath
    extends UseCase<(LearningPath?, Failure?), AdminPathInput> {
  CreatePath(this._repository);

  final PathsAdminRepository _repository;

  @override
  Future<(LearningPath?, Failure?)> call(AdminPathInput input) =>
      _repository.createPath(
        AdminPathInput(
          title: input.title.trim(),
          slug: input.slug?.trim(),
          description: input.description.trim(),
          coverUrl: input.coverUrl?.trim(),
          modality: input.modality,
          durationHours: input.durationHours,
          accessMonths: input.accessMonths,
          discountPercent: input.discountPercent,
          sortOrder: input.sortOrder,
          isPublished: input.isPublished,
        ),
      );
}
