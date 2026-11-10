import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/learning_path.dart';
import '../repositories/paths_repository.dart';

/// Parámetros de UpdatePath.
class UpdatePathParams {
  const UpdatePathParams({required this.id, required this.input});

  final String id;
  final AdminPathInput input;
}

/// Caso de uso: edita la cabecera de una ruta (`PATCH /admin/paths/:id`).
/// `(null, null)` = la ruta no existe.
class UpdatePath
    extends UseCase<(LearningPath?, Failure?), UpdatePathParams> {
  UpdatePath(this._repository);

  final PathsAdminRepository _repository;

  @override
  Future<(LearningPath?, Failure?)> call(UpdatePathParams params) =>
      _repository.updatePath(
        params.id,
        AdminPathInput(
          title: params.input.title.trim(),
          slug: params.input.slug?.trim(),
          description: params.input.description.trim(),
          coverUrl: params.input.coverUrl?.trim(),
          modality: params.input.modality,
          durationHours: params.input.durationHours,
          accessMonths: params.input.accessMonths,
          discountPercent: params.input.discountPercent,
          sortOrder: params.input.sortOrder,
          isPublished: params.input.isPublished,
        ),
      );
}
