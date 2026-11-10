import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/course_curriculum_model.dart';

/// 🔌 DATOS — aula de un curso (`GET /courses/:id/curriculum` y
/// `PATCH /lessons/:id/progress`).
class CurriculumRemoteDataSource {
  CurriculumRemoteDataSource(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  /// El temario es `optionalAuth`: el token solo se manda si hay
  /// sesión, porque el backend calcula el `access` del usuario con él.
  Options? get _sessionOptions {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) return null;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  /// Temario del curso con el gate de pago ya aplicado.
  Future<CourseCurriculumModel> fetchCurriculum(String courseId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/courses/$courseId/curriculum',
        options: _sessionOptions,
      );
      return CourseCurriculumModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cargar el curso');
    }
  }

  /// Marca/desmarca una lección (requiere pago aprobado).
  Future<void> setLessonProgress(
    String lessonId, {
    required bool completed,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/lessons/$lessonId/progress',
        data: {'completed': completed},
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo guardar el avance');
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

final curriculumRemoteDataSourceProvider = Provider<CurriculumRemoteDataSource>(
  (ref) => CurriculumRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  ),
);
