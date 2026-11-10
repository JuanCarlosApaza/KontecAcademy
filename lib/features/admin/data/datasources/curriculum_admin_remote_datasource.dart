import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/new_lesson.dart';
import '../../domain/entities/new_module.dart';
import '../models/admin_curriculum_model.dart';

/// 🔌 DATOS — temario del panel admin. Todas las rutas van bajo
/// `/admin/**` y exigen el JWT del administrador.
abstract interface class CurriculumAdminRemoteDataSource {
  Future<AdminCurriculumModel> fetchCurriculum(String courseId);
  Future<AdminModuleModel> saveModule(NewModule input);
  Future<void> deleteModule(String moduleId);
  Future<AdminLessonModel> saveLesson(String moduleId, NewLesson input);
  Future<void> deleteLesson(String lessonId);
}

class CurriculumAdminRemoteDataSourceImpl
    implements CurriculumAdminRemoteDataSource {
  CurriculumAdminRemoteDataSourceImpl(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  @override
  Future<AdminCurriculumModel> fetchCurriculum(String courseId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/courses/$courseId/curriculum',
        options: _authOptions,
      );
      return AdminCurriculumModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cargar el temario');
    }
  }

  @override
  Future<AdminModuleModel> saveModule(NewModule input) async {
    final moduleId = input.moduleId;
    try {
      final response = moduleId == null
          ? await _dio.post<dynamic>(
              '/admin/courses/${input.courseId}/modules',
              data: {'title': input.title},
              options: _authOptions,
            )
          : await _dio.patch<dynamic>(
              '/admin/modules/$moduleId',
              data: {
                'title': input.title,
                if (input.orderIndex != null) 'orderIndex': input.orderIndex,
              },
              options: _authOptions,
            );

      return _moduleFrom(response.data);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo guardar el módulo');
    }
  }

  @override
  Future<void> deleteModule(String moduleId) async {
    try {
      await _dio.delete<dynamic>('/admin/modules/$moduleId', options: _authOptions);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo borrar el módulo');
    }
  }

  @override
  Future<AdminLessonModel> saveLesson(
    String moduleId,
    NewLesson input,
  ) async {
    final lessonId = input.lessonId;
    final payload = <String, dynamic>{
      'title': input.title,
      'contentType': input.contentType,
      // En el alta las URLs vacías no viajan; en la edición SÍ (null
      // borra el campo, que es como el panel "limpia" una URL).
      if (lessonId == null || input.videoUrl != null)
        'videoUrl': input.videoUrl,
      if (lessonId == null || input.zoomUrl != null) 'zoomUrl': input.zoomUrl,
      if (lessonId == null || input.driveUrl != null)
        'driveUrl': input.driveUrl,
      if (lessonId == null || input.contentText != null)
        'contentText': input.contentText,
      if (lessonId == null || input.attachmentUrl != null)
        'attachmentUrl': input.attachmentUrl,
      if (lessonId == null || input.attachmentName != null)
        'attachmentName': input.attachmentName,
      if (input.orderIndex != null) 'orderIndex': input.orderIndex,
    };

    try {
      final response = lessonId == null
          ? await _dio.post<dynamic>(
              '/admin/modules/$moduleId/lessons',
              data: payload,
              options: _authOptions,
            )
          : await _dio.patch<dynamic>(
              '/admin/lessons/$lessonId',
              data: payload,
              options: _authOptions,
            );

      return AdminLessonModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo guardar la lección');
    }
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _dio.delete<dynamic>('/admin/lessons/$lessonId', options: _authOptions);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo borrar la lección');
    }
  }

  /// El PATCH de módulo devuelve el módulo con sus lecciones; el POST
  /// lo devuelve vacío. En ambos casos la forma es la misma.
  AdminModuleModel _moduleFrom(dynamic data) =>
      AdminModuleModel.fromJson(data as Map<String, dynamic>);

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

final curriculumAdminRemoteDataSourceProvider =
    Provider<CurriculumAdminRemoteDataSource>(
      (ref) => CurriculumAdminRemoteDataSourceImpl(
        ref.watch(dioProvider),
        ref.watch(authRepositoryProvider),
      ),
    );
