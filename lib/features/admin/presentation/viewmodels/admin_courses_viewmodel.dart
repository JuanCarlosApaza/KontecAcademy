import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../landing/presentation/viewmodels/courses_viewmodel.dart';
import '../../../landing/presentation/viewmodels/home_viewmodel.dart';
import '../../admin_injector.dart';
import '../../domain/entities/new_course.dart';

/// STATE del panel admin: estado del envío + resultado de la última creación.
class AdminCoursesState {
  const AdminCoursesState({
    this.isSubmitting = false,
    this.error,
    this.lastCreatedTitle,
    this.successStamp,
  });

  final bool isSubmitting;
  final Failure? error;

  /// Título del último curso creado (para el aviso de éxito).
  final String? lastCreatedTitle;

  /// Marca de tiempo del último éxito: cada creación es "nueva" aunque
  /// el título se repita, así la UI siempre puede reaccionar.
  final int? successStamp;

  AdminCoursesState copyWith({
    bool? isSubmitting,
    Failure? error,
    String? lastCreatedTitle,
    int? successStamp,
    bool clearError = false,
  }) => AdminCoursesState(
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : error ?? this.error,
    lastCreatedTitle: lastCreatedTitle ?? this.lastCreatedTitle,
    successStamp: successStamp ?? this.successStamp,
  );
}

/// ViewModel (MVVM) del panel administrativo.
class AdminCoursesViewModel extends Notifier<AdminCoursesState> {
  @override
  AdminCoursesState build() => const AdminCoursesState();

  /// Crea el curso en la API y refresca el catálogo público
  /// (Capacitaciones y home) para verlo al instante.
  Future<bool> create(NewCourse input) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final (course, failure) = await ref.read(createCourseProvider)(input);

    if (failure != null) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return false;
    }

    state = state.copyWith(
      isSubmitting: false,
      lastCreatedTitle: course.title,
      successStamp: DateTime.now().millisecondsSinceEpoch,
    );

    // El curso nuevo debe verse de inmediato en el sitio público.
    await ref.read(coursesViewModelProvider.notifier).loadCourses();
    await ref.read(homeViewModelProvider.notifier).loadCourses();
    return true;
  }

  /// Actualiza un curso existente en la API y refresca el catálogo.
  /// Es también el "eliminar" lógico del panel (status → 'inactive').
  Future<bool> update(String id, NewCourse input) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final (course, failure) = await ref.read(updateCourseProvider)(
      UpdateCourseParams(id: id, input: input),
    );

    if (failure != null) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return false;
    }

    state = state.copyWith(
      isSubmitting: false,
      lastCreatedTitle: course.title,
      successStamp: DateTime.now().millisecondsSinceEpoch,
    );

    // El curso actualizado debe verse de inmediato en el sitio público.
    await ref.read(coursesViewModelProvider.notifier).loadCourses();
    await ref.read(homeViewModelProvider.notifier).loadCourses();
    return true;
  }

  /// Recarga a mano la lista de cursos del catálogo.
  Future<void> refreshCatalog() async {
    await ref.read(coursesViewModelProvider.notifier).loadCourses();
    await ref.read(homeViewModelProvider.notifier).loadCourses();
  }
}

final adminCoursesViewModelProvider =
    NotifierProvider<AdminCoursesViewModel, AdminCoursesState>(
      AdminCoursesViewModel.new,
    );
