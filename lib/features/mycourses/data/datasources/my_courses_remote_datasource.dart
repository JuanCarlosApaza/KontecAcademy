import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/enrolled_course_model.dart';

/// 🔌 DATOS — "Mis cursos" remoto (`GET /my/courses` con el JWT).
class MyCoursesRemoteDataSource {
  MyCoursesRemoteDataSource(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  /// Inscripciones del usuario con su estado (approved = con acceso).
  Future<List<EnrolledCourseModel>> fetchMyCourses() async {
    try {
      final response = await _dio.get<dynamic>(
        '/my/courses',
        options: _authOptions,
      );
      final rows = response.data as List<dynamic>;
      return rows
          .map(
            (row) => EnrolledCourseModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      final type = e.type;
      if (type == DioExceptionType.connectionError ||
          type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.receiveTimeout ||
          type == DioExceptionType.sendTimeout) {
        throw NetworkException(e.message ?? 'Sin conexión con el servidor');
      }

      final data = e.response?.data;
      final apiMessage = data is Map && data['error'] is String
          ? data['error'] as String
          : null;
      throw ServerException(
        apiMessage ?? e.message ?? 'No se pudieron cargar tus cursos',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final myCoursesRemoteDataSourceProvider = Provider<MyCoursesRemoteDataSource>(
  (ref) => MyCoursesRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  ),
);
