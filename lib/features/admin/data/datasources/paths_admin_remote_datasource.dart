import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// 🔌 DATOS — CRUD de rutas del panel admin (`/admin/paths`).
///
/// Habla con la API Node adjuntando el JWT de Supabase; el backend
/// valida el permiso `courses:create` en cada escritura.
final pathsAdminRemoteDataSourceProvider = Provider<PathsAdminRemoteDataSource>(
  (ref) => PathsAdminRemoteDataSourceImpl(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  ),
);

abstract interface class PathsAdminRemoteDataSource {
  /// Todas las rutas (incluye borradores).
  Future<List<Map<String, dynamic>>> listPaths();

  /// Crea una ruta; devuelve la fila creada con sus cursos.
  Future<Map<String, dynamic>> createPath(Map<String, dynamic> body);

  /// Editla cabecera de una ruta; 404 si no existe.
  Future<Map<String, dynamic>> updatePath(String id, Map<String, dynamic> body);

  /// Reemplaza los cursos de la ruta (`PUT .../courses`).
  Future<Map<String, dynamic>> setPathCourses(
    String id,
    List<Map<String, dynamic>> courses,
  );

  /// Borra la ruta; 404 si no existía.
  Future<void> deletePath(String id);
}

class PathsAdminRemoteDataSourceImpl implements PathsAdminRemoteDataSource {
  PathsAdminRemoteDataSourceImpl(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  @override
  Future<List<Map<String, dynamic>>> listPaths() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/paths',
        options: _authOptions,
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar las rutas');
    }
  }

  @override
  Future<Map<String, dynamic>> createPath(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(
        '/admin/paths',
        data: body,
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo crear la ruta');
    }
  }

  @override
  Future<Map<String, dynamic>> updatePath(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/admin/paths/$id',
        data: body,
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo actualizar la ruta');
    }
  }

  @override
  Future<Map<String, dynamic>> setPathCourses(
    String id,
    List<Map<String, dynamic>> courses,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/admin/paths/$id/courses',
        data: {'courses': courses},
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron guardar los cursos de la ruta');
    }
  }

  @override
  Future<void> deletePath(String id) async {
    try {
      await _dio.delete<dynamic>('/admin/paths/$id', options: _authOptions);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo eliminar la ruta');
    }
  }

  /// Conexión caída → [NetworkException]; otro caso → [ServerException]
  /// con el mensaje que devolvió la API (400/403/404).
  Exception _serverOrNetwork(DioException e, String fallback) {
    final type = e.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return NetworkException(e.message ?? 'Sin conexión con el servidor');
    }

    final data = e.response?.data;
    final apiMessage = data is Map && data['error'] is String
        ? data['error'] as String
        : null;

    return ServerException(
      apiMessage ?? e.message ?? fallback,
      statusCode: e.response?.statusCode,
    );
  }
}
