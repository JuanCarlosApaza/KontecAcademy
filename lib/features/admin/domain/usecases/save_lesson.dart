import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_curriculum.dart';
import '../entities/new_lesson.dart';
import '../repositories/course_admin_repository.dart';

/// Parámetros de [SaveLesson]: la lección siempre pertenece a un
/// módulo, y el id del módulo viaja en el payload de la ruta.
class SaveLessonParams extends Equatable {
  const SaveLessonParams({required this.moduleId, required this.input});

  final String moduleId;
  final NewLesson input;

  @override
  List<Object?> get props => [moduleId, input];
}

/// Caso de uso: crear o editar una lección del temario. El "mover" es un
/// PATCH con `orderIndex` (1-based dentro de su módulo).
class SaveLesson
    extends UseCase<(AdminLesson?, Failure?), SaveLessonParams> {
  SaveLesson(this._repository);

  final CourseAdminRepository _repository;

  @override
  Future<(AdminLesson?, Failure?)> call(SaveLessonParams params) {
    return _repository.saveLesson(params.moduleId, params.input);
  }
}
