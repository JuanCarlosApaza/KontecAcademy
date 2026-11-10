import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/session_roles_model.dart';

/// 🔌 DATOS — sesión actual del panel admin.
///
/// Único lugar que llama a `GET /me` con el JWT de Supabase (el
/// backend valida el token y devuelve roles + permisos).
abstract interface class AdminSessionRemoteDataSource {
  /// `null` = no hay sesión (no se hace la petición).
  Future<SessionRolesModel?> fetchSession();
}

class AdminSessionRemoteDataSourceImpl implements AdminSessionRemoteDataSource {
  AdminSessionRemoteDataSourceImpl(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  @override
  Future<SessionRolesModel?> fetchSession() async {
    final token = _auth.accessToken;
    if (token == null) return null;

    try {
      final response = await _dio.get<dynamic>(
        '/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return SessionRolesModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cargar la sesión del panel');
    }
  }

  /// Conexión caída → [NetworkException]; otro caso → [ServerException]
  /// con el mensaje que devolvió la API.
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

final adminSessionRemoteDataSourceProvider =
    Provider<AdminSessionRemoteDataSource>(
      (ref) => AdminSessionRemoteDataSourceImpl(
        ref.watch(dioProvider),
        ref.watch(authRepositoryProvider),
      ),
    );
