import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category_model.dart';
import '../models/training_course_model.dart';

/// Fuente de datos remota del catálogo: ÚNICO lugar que habla con la API
/// (`GET /courses` y `GET /categories` del server Node).
final courseRemoteDataSourceProvider = Provider<CourseRemoteDataSource>(
  (ref) => CourseRemoteDataSourceImpl(ref.watch(dioProvider)),
);

abstract interface class CourseRemoteDataSource {
  Future<List<TrainingCourseModel>> fetchCourses();

  /// Curso por id (`GET /courses/:id`). Lanza [ServerException] con
  /// 404 si no existe.
  Future<TrainingCourseModel> fetchCourseById(String id);

  Future<List<CategoryModel>> fetchCategories();
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  CourseRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<TrainingCourseModel>> fetchCourses() async {
    try {
      final response = await _dio.get('/courses');
      final data = (response.data as List).cast<Map<String, dynamic>>();
      return data.map(TrainingCourseModel.fromJson).toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al obtener los cursos');
    }
  }

  @override
  Future<TrainingCourseModel> fetchCourseById(String id) async {
    try {
      final response = await _dio.get('/courses/$id');
      return TrainingCourseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al obtener el curso');
    }
  }

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _dio.get('/categories');
      final data = (response.data as List).cast<Map<String, dynamic>>();
      return data.map(CategoryModel.fromJson).toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al obtener las categorías');
    }
  }

  /// Conexión caída → [NetworkException]; cualquier otro caso → [ServerException].
  Exception _serverOrNetwork(DioException e, String fallback) {
    final type = e.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return NetworkException(e.message ?? 'Sin conexión con el servidor');
    }
    return ServerException(
      e.message ?? fallback,
      statusCode: e.response?.statusCode,
    );
  }
}
