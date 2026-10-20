import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

/// Implementación concreta del repositorio.
///
/// Su responsabilidad: traducir excepciones (`data`) en fallas (`domain`)
/// y convertir modelos en entidades. Nada más.
/// Para cambiar la API por una fuente local, solo se reemplaza este wiring.
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskRemoteDataSourceProvider)),
);

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remote);

  final TaskRemoteDataSource _remote;

  @override
  Future<(List<Task>, Failure?)> getTasks() async {
    try {
      final models = await _remote.fetchTasks();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on ServerException catch (e) {
      return (<Task>[], ServerFailure(e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return (<Task>[], CacheFailure(e.message));
    } catch (e) {
      return (<Task>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(Task, Failure?)> createTask(String title) async {
    try {
      final model = await _remote.createTask(title);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (_emptyTask(title), ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return (_emptyTask(title), UnknownFailure(e.toString()));
    }
  }

  Task _emptyTask(String title) => Task(id: '', title: title);
}
