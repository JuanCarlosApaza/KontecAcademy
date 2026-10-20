import '../../../../core/error/failures.dart';
import '../entities/task.dart';

/// Contrato (interfaz) del repositorio.
///
/// El dominio SOLO conoce esta abstracción: no sabe si los datos vienen
/// de una API REST, de una base de datos local o de un mock.
/// Quien decide eso es la capa `data`.
abstract interface class TaskRepository {
  /// Devuelve los tareas o un [Failure] si algo sale mal.
  Future<(List<Task>, Failure?)> getTasks();

  Future<(Task, Failure?)> createTask(String title);
}
