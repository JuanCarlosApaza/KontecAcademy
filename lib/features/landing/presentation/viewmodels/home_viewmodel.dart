import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/training_course.dart';
import '../../landing_injector.dart';

/// STATE: todo lo que el home necesita para pintarse.
class HomeState {
  const HomeState({
    this.courses = const [],
    this.isLoading = false,
    this.error,
  });

  final List<TrainingCourse> courses;
  final bool isLoading;
  final Failure? error;

  HomeState copyWith({
    List<TrainingCourse>? courses,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) => HomeState(
    courses: courses ?? this.courses,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

/// ViewModel del home (MVVM): único puente entre UI y dominio.
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    Future.microtask(loadCourses);
    return const HomeState(isLoading: true);
  }

  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final (courses, failure) = await ref.read(getFeaturedCoursesProvider)(
      NoParams(),
    );

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return;
    }
    state = state.copyWith(isLoading: false, courses: courses);
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
