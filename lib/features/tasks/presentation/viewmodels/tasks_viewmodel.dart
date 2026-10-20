import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../task_injector.dart';

/// STATE: todo lo que la UI necesita para pintar la pantalla.
class TasksState {
  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.isAdding = false,
    this.error,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool isAdding;
  final Failure? error;

  TasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? isAdding,
    Failure? error,
    bool clearError = false,
  }) =>
      TasksState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        isAdding: isAdding ?? this.isAdding,
        error: clearError ? null : error ?? this.error,
      );
}

/// VIEWMODEL (patrón MVVM) de la lista de tareas.
///
/// ÚNICO puente entre la UI y el dominio:
///  - llama a los casos de uso (jamás a repositories, datasources ni Dio)
///  - publica [state], que los Widgets observan con `ref.watch`
///  - los Widgets solo le envían eventos mediante sus métodos públicos
class TasksViewModel extends Notifier<TasksState> {
  @override
  TasksState build() {
    Future.microtask(loadTasks);
    return const TasksState(isLoading: true);
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final (tasks, failure) = await ref.read(getTasksProvider)(NoParams());

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return;
    }
    state = state.copyWith(isLoading: false, tasks: tasks);
  }

  Future<void> addTask(String title) async {
    if (title.trim().isEmpty) return;

    state = state.copyWith(isAdding: true, clearError: true);
    try {
      final (_, failure) = await ref
          .read(createTaskProvider)(CreateTaskParams(title: title));
      if (failure != null) {
        state = state.copyWith(isAdding: false, error: failure);
        return;
      }
      // La API de demo no persiste cambios: recargamos la lista.
      await loadTasks();
    } finally {
      state = state.copyWith(isAdding: false);
    }
  }

  void toggleTask(String id) {
    state = state.copyWith(
      clearError: true,
      tasks: [
        for (final task in state.tasks)
          task.id == id ? task.copyWith(isDone: !task.isDone) : task,
      ],
    );
  }
}

final tasksViewModelProvider =
    NotifierProvider<TasksViewModel, TasksState>(TasksViewModel.new);
