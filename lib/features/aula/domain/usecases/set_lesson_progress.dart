import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/curriculum_repository.dart';

/// Entrada de [SetLessonProgress].
class SetLessonProgressParams {
  const SetLessonProgressParams({
    required this.lessonId,
    required this.completed,
  });

  final String lessonId;
  final bool completed;
}

/// Caso de uso: marcar/desmarcar una lección como completada.
///
/// Devuelve el `Failure` si algo falla (403 = el pago aún no está
/// aprobado) o null si todo fue bien.
class SetLessonProgress extends UseCase<Failure?, SetLessonProgressParams> {
  SetLessonProgress(this._repository);

  final CurriculumRepository _repository;

  @override
  Future<Failure?> call(SetLessonProgressParams params) {
    return _repository.setLessonProgress(
      params.lessonId,
      completed: params.completed,
    );
  }
}
