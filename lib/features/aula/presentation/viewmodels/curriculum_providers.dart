import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../aula_injector.dart';
import '../../domain/entities/course_curriculum.dart';
import '../../domain/usecases/set_lesson_progress.dart';

/// Temario del curso (`/capacitaciones/:id/aula` y la ficha del curso).
///
/// El backend lo sirve con `optionalAuth`, así que REACCIONA al login
/// y al logout: al cambiar la sesión se vuelve a pedir y el `access`
/// se recalcula.
final curriculumProvider = FutureProvider.family<CourseCurriculum?, String>((
  ref,
  courseId,
) async {
  final (curriculum, failure) = await ref.watch(getCurriculumProvider)(
    courseId,
  );
  if (failure != null) throw failure; // Failure → mensaje en la UI
  return curriculum;
});

/// Estado de marcar/desmarcar una lección como completada.
class LessonProgressState {
  const LessonProgressState({this.isSaving = false, this.error});

  final bool isSaving;
  final Failure? error;

  LessonProgressState copyWith({
    bool? isSaving,
    Failure? error,
    bool clearError = false,
  }) => LessonProgressState(
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Marca/desmarca el avance de una lección y recarga el temario para
/// que el contador de progreso se actualice.
class LessonProgressViewModel extends Notifier<LessonProgressState> {
  @override
  LessonProgressState build() => const LessonProgressState();

  Future<bool> toggle({
    required String courseId,
    required String lessonId,
    required bool completed,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    final failure = await ref.read(setLessonProgressProvider)(
      SetLessonProgressParams(lessonId: lessonId, completed: completed),
    );

    if (failure != null) {
      state = state.copyWith(isSaving: false, error: failure);
      return false;
    }

    // El temario trae `completedLessons`: se vuelve a pedir para que el
    // progreso refleje el cambio guardado.
    ref.invalidate(curriculumProvider(courseId));
    state = state.copyWith(isSaving: false);
    return true;
  }
}

final lessonProgressViewModelProvider =
    NotifierProvider<LessonProgressViewModel, LessonProgressState>(
      LessonProgressViewModel.new,
    );
