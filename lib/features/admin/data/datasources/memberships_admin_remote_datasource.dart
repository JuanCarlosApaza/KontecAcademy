import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// 🔌 DATOS — membresías y planes del panel admin.
///
/// Endpoints (`/admin/membership-plans`, `/admin/memberships`) con el
/// JWT de Supabase; el backend valida `courses:view` / `courses:create`.
final membershipsAdminRemoteDataSourceProvider =
    Provider<MembershipsAdminRemoteDataSource>(
      (ref) => MembershipsAdminRemoteDataSourceImpl(
        ref.watch(dioProvider),
        ref.watch(authRepositoryProvider),
      ),
    );

abstract interface class MembershipsAdminRemoteDataSource {
  Future<List<Map<String, dynamic>>> listPlans();
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updatePlan(String id, Map<String, dynamic> body);
  Future<void> deletePlan(String id);

  Future<List<Map<String, dynamic>>> listMemberships();
  Future<Map<String, dynamic>> grant(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateMembership(
    String id,
    Map<String, dynamic> body,
  );
}

class MembershipsAdminRemoteDataSourceImpl
    implements MembershipsAdminRemoteDataSource {
  MembershipsAdminRemoteDataSourceImpl(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  @override
  Future<List<Map<String, dynamic>>> listPlans() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/membership-plans',
        options: _authOptions,
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar los planes');
    }
  }

  @override
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(
        '/admin/membership-plans',
        data: body,
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo crear el plan');
    }
  }

  @override
  Future<Map<String, dynamic>> updatePlan(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/admin/membership-plans/$id',
        data: body,
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo actualizar el plan');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _dio.delete<dynamic>(
        '/admin/membership-plans/$id',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo eliminar el plan');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listMemberships() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/memberships',
        options: _authOptions,
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar las membresías');
    }
  }

  @override
  Future<Map<String, dynamic>> grant(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(
        '/admin/memberships',
        data: body,
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo otorgar la membresía');
    }
  }

  @override
  Future<Map<String, dynamic>> updateMembership(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/admin/memberships/$id',
        data: body,
        options: _authOptions,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo actualizar la membresía');
    }
  }

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
