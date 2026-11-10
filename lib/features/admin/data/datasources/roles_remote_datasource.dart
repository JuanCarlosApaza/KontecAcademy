import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/roles_matrix_model.dart';

/// 🔌 DATOS — roles y permisos del panel (`/admin/roles`).
///
/// Habla con la API Node adjuntando el JWT de Supabase; el backend
/// valida el permiso `roles:manage` en cada petición.
abstract interface class RolesRemoteDataSource {
  Future<RolesMatrixModel> fetchMatrix();

  /// 201 con el rol creado; el backend responde 400 si el nombre
  /// ya existe o no cumple el formato (lanza [ServerException]).
  Future<Map<String, dynamic>> createRole({
    required String name,
    required String description,
  });

  Future<void> savePermissions({
    required String roleId,
    required List<String> codes,
  });

  Future<void> deleteRole(String roleId);
}

class RolesRemoteDataSourceImpl implements RolesRemoteDataSource {
  RolesRemoteDataSourceImpl(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  @override
  Future<RolesMatrixModel> fetchMatrix() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/roles',
        options: _authOptions,
      );
      return RolesMatrixModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar los roles');
    }
  }

  @override
  Future<Map<String, dynamic>> createRole({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/admin/roles',
        data: {'name': name, 'description': description},
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo crear el rol');
    }
  }

  @override
  Future<void> savePermissions({
    required String roleId,
    required List<String> codes,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/admin/roles/$roleId/permissions',
        data: {'codes': codes},
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron guardar los permisos');
    }
  }

  @override
  Future<void> deleteRole(String roleId) async {
    try {
      await _dio.delete<dynamic>(
        '/admin/roles/$roleId',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo eliminar el rol');
    }
  }

  /// Conexión caída → [NetworkException]; otro caso → [ServerException]
  /// con el mensaje que devolvió la API (400/403/404/409).
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

final rolesRemoteDataSourceProvider = Provider<RolesRemoteDataSource>(
  (ref) => RolesRemoteDataSourceImpl(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  ),
);
