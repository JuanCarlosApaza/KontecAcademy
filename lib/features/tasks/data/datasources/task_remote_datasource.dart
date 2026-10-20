import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/task_model.dart';

/// Fuente de datos remota: ÚNICO lugar que habla con la API.
final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>(
  (ref) => TaskRemoteDataSourceImpl(ref.watch(dioProvider)),
);

abstract interface class TaskRemoteDataSource {
  Future<List<TaskModel>> fetchTasks();

  Future<TaskModel> createTask(String title);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<TaskModel>> fetchTasks() async {
    try {
      final response = await _dio.get('/todos');
      final data = (response.data as List).cast<Map<String, dynamic>>();
      return data.map(TaskModel.fromJson).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Error al obtener tareas',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<TaskModel> createTask(String title) async {
    try {
      final response = await _dio.post('/todos', data: {'title': title});
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Error al crear la tarea',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
