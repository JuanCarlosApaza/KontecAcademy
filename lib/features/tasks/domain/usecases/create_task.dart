import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import 'get_tasks.dart';

/// Caso de uso: crear una nueva tarea.
class CreateTask extends UseCase<(Task, Failure?), CreateTaskParams> {
  CreateTask(this._repository);

  final TaskRepository _repository;

  @override
  Future<(Task, Failure?)> call(CreateTaskParams params) {
    return _repository.createTask(params.title.trim());
  }
}
