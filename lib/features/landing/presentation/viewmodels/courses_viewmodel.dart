import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/training_course.dart';
import '../../landing_injector.dart';

/// STATE: todo lo que la pantalla de Capacitaciones necesita para pintarse.
class CoursesState {
  const CoursesState({
    this.courses = const [],
    this.categories = const [],
    this.selectedCategory = 'Todas',
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<TrainingCourse> courses;

  /// Nombres de las categorías del catálogo (chips de filtro).
  /// Vienen de `GET /categories`; "Todas" se añade en la UI.
  final List<String> categories;

  /// Categoría seleccionada en los chips ("Todas" = sin filtro).
  final String selectedCategory;

  /// Texto del buscador (coincide con título o categoría).
  final String searchQuery;

  final bool isLoading;
  final Failure? error;

  /// Lista ya filtrada por categoría + búsqueda: lo que pinta la UI.
  List<TrainingCourse> get visibleCourses {
    final query = searchQuery.trim().toLowerCase();
    return courses.where((course) {
      final matchCategory =
          selectedCategory == 'Todas' || course.category == selectedCategory;
      final matchQuery =
          query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query);
      return matchCategory && matchQuery;
    }).toList();
  }

  CoursesState copyWith({
    List<TrainingCourse>? courses,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) => CoursesState(
    courses: courses ?? this.courses,
    categories: categories ?? this.categories,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    searchQuery: searchQuery ?? this.searchQuery,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

/// ViewModel (MVVM) de la pantalla de Capacitaciones.
class CoursesViewModel extends Notifier<CoursesState> {
  @override
  CoursesState build() {
    Future.microtask(loadCourses);
    return const CoursesState(isLoading: true);
  }

  /// Carga cursos y categorías EN PARALELO desde la API real.
  /// Si `/categories` falla o vuelve vacío, las categorías se derivan
  /// de los cursos cargados (los chips nunca quedan vacíos sin datos).
  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final coursesFuture = ref.read(getAllCoursesProvider)(NoParams());
    final categoriesFuture = ref.read(getCategoriesProvider)(NoParams());

    final (courses, failure) = await coursesFuture;
    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return;
    }

    final (categories, categoriesFailure) = await categoriesFuture;
    final names = (categoriesFailure != null || categories.isEmpty)
        ? <String>{
            for (final course in courses)
              if (course.category.isNotEmpty) course.category,
          }.toList()
        : [for (final category in categories) category.name];

    state = state.copyWith(
      isLoading: false,
      courses: courses,
      categories: names,
    );
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category, clearError: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, clearError: true);
  }
}

final coursesViewModelProvider =
    NotifierProvider<CoursesViewModel, CoursesState>(CoursesViewModel.new);
