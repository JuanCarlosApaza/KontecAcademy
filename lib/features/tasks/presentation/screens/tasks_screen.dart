import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/tasks_viewmodel.dart';
import '../widgets/task_tile.dart';

/// VIEW de MVVM: solo dibuja el [TasksState] y envía eventos al ViewModel.
/// No conoce casos de uso, repositorios ni Dio.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksViewModelProvider);
    final viewModel = ref.read(tasksViewModelProvider.notifier);

    ref.listen(tasksViewModelProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: Center(
        // Ancho máximo: la misma vista se ve bien en web y en móvil.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'Nueva tarea',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _addTask,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: state.isAdding
                          ? null
                          : () => _addTask(_controller.text),
                      child: state.isAdding
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Añadir'),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(state, viewModel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(TasksState state, TasksViewModel viewModel) {
    if (state.isLoading && state.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.tasks.isEmpty && state.error == null) {
      return const Center(child: Text('No hay tareas todavía.'));
    }
    if (state.tasks.isEmpty && state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!.message),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: viewModel.loadTasks,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadTasks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.tasks.length,
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return TaskTile(
            key: ValueKey(task.id),
            task: task,
            onToggle: () => viewModel.toggleTask(task.id),
          );
        },
      ),
    );
  }

  void _addTask(String title) {
    ref.read(tasksViewModelProvider.notifier).addTask(title);
    _controller.clear();
  }
}
