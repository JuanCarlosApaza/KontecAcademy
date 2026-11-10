import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../landing/data/models/training_course_model.dart';
import '../../domain/entities/new_course.dart';

/// Fuente de datos remota del panel admin: ÚNICO lugar que escribe
/// en el catálogo (`POST/PATCH /courses` del server Node).
final courseAdminRemoteDataSourceProvider =
    Provider<CourseAdminRemoteDataSource>(
      (ref) => CourseAdminRemoteDataSourceImpl(
        ref.watch(dioProvider),
        ref.watch(authRepositoryProvider),
      ),
    );

abstract interface class CourseAdminRemoteDataSource {
  /// Devuelve el curso tal como quedó persistido (con categoría embebida).
  Future<TrainingCourseModel> createCourse(NewCourse input);

  /// Actualiza un curso existente (incluye el "eliminar" lógico del
  /// panel, que solo cambia `status` a 'inactive').
  Future<TrainingCourseModel> updateCourse(String id, NewCourse input);
}

class CourseAdminRemoteDataSourceImpl implements CourseAdminRemoteDataSource {
  CourseAdminRemoteDataSourceImpl(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  Map<String, dynamic> _payload(NewCourse input) => {
    'title': input.title,
    'description': input.description,
    'imageUrl': input.imageUrl,
    'categoryId': input.categoryId,
    'modality': input.modality,
    'totalHours': input.totalHours,
    'totalWeeks': input.totalWeeks,
    'price': input.price,
    'compareAtPrice': input.compareAtPrice,
    'status': input.status,
    'professorBio': input.professorBio,
    'teachingMethod': input.teachingMethod,
    'targetAudience': input.targetAudience,
    'certificateInfo': input.certificateInfo,
    'careerOpportunities': input.careerOpportunities,
  };

  @override
  Future<TrainingCourseModel> createCourse(NewCourse input) async {
    try {
      final response = await _dio.post('/courses', data: _payload(input));
      return TrainingCourseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al crear el curso');
    }
  }

  @override
  Future<TrainingCourseModel> updateCourse(String id, NewCourse input) async {
    try {
      final response = await _dio.patch(
        '/courses/$id',
        data: _payload(input),
        options: _authOptions,
      );
      return TrainingCourseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'Error al actualizar el curso');
    }
  }

  /// Conexión caída → [NetworkException]; otro caso → [ServerException]
  /// con el mensaje que devolvió la API (ej: "El campo title es obligatorio").
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
