import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/learning_path_model.dart';

/// Fuente de datos remota de las rutas: ÚNICO lugar que habla con la
/// API (`GET /paths` y `GET /paths/:slug` del server Node).
final learningPathRemoteDataSourceProvider =
    Provider<LearningPathRemoteDataSource>(
      (ref) => LearningPathRemoteDataSourceImpl(ref.watch(dioProvider)),
    );

abstract interface class LearningPathRemoteDataSource {
  /// Rutas publicadas con sus cursos embebidos.
  Future<List<LearningPathModel>> fetchPaths();

  /// Ruta por slug. Lanza [ServerException] con 404 si no existe.
  Future<LearningPathModel> fetchPathBySlug(String slug);
}

class LearningPathRemoteDataSourceImpl implements LearningPathRemoteDataSource {
  LearningPathRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<LearningPathModel>> fetchPaths() async {
    try {
      final response = await _dio.get('/paths');
      final data = (response.data as List).cast<Map<String, dynamic>>();
      return data.map(LearningPathModel.fromJson).toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al obtener las rutas');
    }
  }

  @override
  Future<LearningPathModel> fetchPathBySlug(String slug) async {
    try {
      final response = await _dio.get('/paths/$slug');
      return LearningPathModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al obtener la ruta');
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
