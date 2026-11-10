import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/membership_plan_model.dart';

/// 🔌 DATOS — planes de membresía (`GET /membership-plans`).
final membershipPlanRemoteDataSourceProvider =
    Provider<MembershipPlanRemoteDataSource>(
      (ref) => MembershipPlanRemoteDataSourceImpl(ref.watch(dioProvider)),
    );

abstract interface class MembershipPlanRemoteDataSource {
  /// Planes activos (los que puede comprar el usuario).
  Future<List<MembershipPlanModel>> fetchPlans();
}

class MembershipPlanRemoteDataSourceImpl
    implements MembershipPlanRemoteDataSource {
  MembershipPlanRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<MembershipPlanModel>> fetchPlans() async {
    try {
      final response = await _dio.get('/membership-plans');
      final data = (response.data as List).cast<Map<String, dynamic>>();
      return data.map(MembershipPlanModel.fromJson).toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al obtener los planes');
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
