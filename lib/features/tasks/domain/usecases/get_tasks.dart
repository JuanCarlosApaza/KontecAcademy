import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Caso de uso: obtener la lista de tareas.
class GetTasks extends UseCase<(List<Task>, Failure?), NoParams> {
  GetTasks(this._repository);

  final TaskRepository _repository;

  @override
  Future<(List<Task>, Failure?)> call(NoParams params) {
    return _repository.getTasks();
  }
}

class CreateTaskParams extends Equatable {
  const CreateTaskParams({required this.title});

  final String title;

  @override
  List<Object?> get props => [title];
}
