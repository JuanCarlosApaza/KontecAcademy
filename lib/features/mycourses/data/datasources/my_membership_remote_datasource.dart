import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/entities/my_membership.dart';

/// 🔌 DATOS — membresía del usuario (`GET /my/membership`).
final myMembershipRemoteDataSourceProvider =
    Provider<MyMembershipRemoteDataSource>(
      (ref) => MyMembershipRemoteDataSourceImpl(
        ref.watch(dioProvider),
        ref.watch(authRepositoryProvider),
      ),
    );

abstract interface class MyMembershipRemoteDataSource {
  /// Membresía activa del JWT; null si no tiene una vigente.
  Future<MyMembership?> fetchMyMembership();
}

class MyMembershipRemoteDataSourceImpl
    implements MyMembershipRemoteDataSource {
  MyMembershipRemoteDataSourceImpl(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  @override
  Future<MyMembership?> fetchMyMembership() async {
    try {
      final response = await _dio.get<dynamic>(
        '/my/membership',
        options: _authOptions,
      );
      final data = response.data;
      if (data == null) return null;

      final json = data as Map<String, dynamic>;
      return MyMembership(
        planName: json['planName'] as String? ?? '',
        months: (json['months'] as num?)?.toInt() ?? 0,
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cargar tu membresía');
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
    return ServerException(
      e.message ?? fallback,
      statusCode: e.response?.statusCode,
    );
  }
}

/// Membresía activa del usuario; reacciona a login/logout (sin este
/// watch, el valor quedaría congelado tras iniciar sesión).
final myMembershipProvider = FutureProvider<MyMembership?>((ref) async {
  ref.watch(authUserProvider);
  final hasSession = ref.watch(isAuthenticatedProvider);
  if (!hasSession) return null;

  final datasource = ref.watch(myMembershipRemoteDataSourceProvider);
  return datasource.fetchMyMembership();
});
