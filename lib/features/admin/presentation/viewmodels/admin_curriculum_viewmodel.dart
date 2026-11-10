import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../admin_injector.dart';
import '../../domain/entities/admin_curriculum.dart';
import '../../domain/entities/new_lesson.dart';
import '../../domain/entities/new_module.dart';

/// Estado del editor de temario ("Temario" en Cursos).
class AdminCurriculumState {
  const AdminCurriculumState({
    this.courseId,
    this.courseTitle = '',
    this.modules = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitError,
    this.successMessage,
  });

  final String? courseId;
  final String courseTitle;
  final List<AdminModule> modules;
  final bool isLoading;
  final bool isSubmitting;

  /// Error de CARGA (se muestra a pantalla completa).
  final Failure? error;

  /// Error de una GUARDADO (se muestra inline en el formulario).
  final String? submitError;

  /// Última operación exitosa (para el snackbar del diálogo).
  final String? successMessage;

  AdminCurriculumState copyWith({
    String? courseId,
    String? courseTitle,
    List<AdminModule>? modules,
    bool? isLoading,
    bool? isSubmitting,
    Failure? error,
    String? submitError,
    String? successMessage,
    bool clearError = false,
    bool clearSubmitError = false,
    bool clearSuccess = false,
  }) => AdminCurriculumState(
    courseId: courseId ?? this.courseId,
    courseTitle: courseTitle ?? this.courseTitle,
    modules: modules ?? this.modules,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : (error ?? this.error),
    submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
  );
}

/// CRUD del temario: módulos y lecciones de un curso.
///
/// Tras cada mutación se vuelve a PEDIR el temario al servidor (que es
/// quien calcula los `orderIndex` definitivos).
class AdminCurriculumViewModel extends Notifier<AdminCurriculumState> {
  @override
  AdminCurriculumState build() => const AdminCurriculumState();

  Future<void> load(String courseId) async {
    state = state.copyWith(
      courseId: courseId,
      isLoading: true,
      clearError: true,
      clearSubmitError: true,
    );

    final (curriculum, failure) = await ref
        .read(getAdminCurriculumProvider)(courseId);

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return;
    }

    state = state.copyWith(
      courseTitle: curriculum?.courseTitle ?? '',
      modules: curriculum?.modules ?? const [],
      isLoading: false,
    );
  }

  Future<bool> saveModule(NewModule input) async {
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    final (module, failure) = await ref.read(saveModuleProvider)(input);
    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    await _reload();
    state = state.copyWith(
      isSubmitting: false,
      successMessage: input.isEditing ? 'Módulo actualizado ✅' : 'Módulo añadido ✅',
    );
    return module != null;
  }

  Future<bool> deleteModule(AdminModule module) async {
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    final (ok, failure) = await ref.read(deleteModuleProvider)(module.id);
    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    await _reload();
    state = state.copyWith(
      isSubmitting: false,
      successMessage: 'Módulo borrado ✅',
    );
    return ok;
  }

  Future<bool> saveLesson(String moduleId, NewLesson input) async {
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    final (lesson, failure) = await ref.read(saveLessonProvider)(
      SaveLessonParams(moduleId: moduleId, input: input),
    );
    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    await _reload();
    state = state.copyWith(
      isSubmitting: false,
      successMessage: input.isEditing ? 'Lección actualizada ✅' : 'Lección añadida ✅',
    );
    return lesson != null;
  }

  Future<bool> deleteLesson(AdminLesson lesson) async {
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    final (ok, failure) = await ref.read(deleteLessonProvider)(lesson.id);
    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    await _reload();
    state = state.copyWith(
      isSubmitting: false,
      successMessage: 'Lección borrada ✅',
    );
    return ok;
  }

  /// Mueve un módulo una posición arriba/abajo (orderIndex 1-based).
  Future<bool> moveModule(AdminModule module, {required bool up}) {
    final target = module.orderIndex + (up ? -1 : 1);
    if (target < 1) return Future.value(false);

    return saveModule(
      NewModule(
        courseId: state.courseId ?? '',
        moduleId: module.id,
        title: module.title,
        orderIndex: target,
      ),
    );
  }

  /// Mueve una lección una posición arriba/abajo dentro de su módulo.
  Future<bool> moveLesson(
    AdminModule module,
    AdminLesson lesson, {
    required bool up,
  }) {
    final target = lesson.orderIndex + (up ? -1 : 1);
    if (target < 1) return Future.value(false);

    return saveLesson(
      module.id,
      NewLesson(
        lessonId: lesson.id,
        title: lesson.title,
        contentType: lesson.contentType,
        videoUrl: lesson.videoUrl,
        zoomUrl: lesson.zoomUrl,
        driveUrl: lesson.driveUrl,
        contentText: lesson.contentText,
        attachmentUrl: lesson.attachmentUrl,
        attachmentName: lesson.attachmentName,
        orderIndex: target,
      ),
    );
  }

  /// Limpia el mensaje de éxito (lo consume el diálogo tras el snackbar).
  void clearSuccess() => state = state.copyWith(clearSuccess: true);

  Future<void> _reload() async {
    final courseId = state.courseId;
    if (courseId != null) await load(courseId);
  }
}

final adminCurriculumViewModelProvider =
    NotifierProvider<AdminCurriculumViewModel, AdminCurriculumState>(
      AdminCurriculumViewModel.new,
    );
