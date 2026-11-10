import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../landing/data/models/category_model.dart';
import '../../domain/entities/new_admin_user.dart';
import '../models/abandoned_cart_item_model.dart';
import '../models/admin_stats_model.dart';
import '../models/admin_user_record_model.dart';
import '../models/course_participant_model.dart';
import '../models/created_user_model.dart';
import '../models/payment_record_model.dart';
import '../models/student_profile_model.dart';
import '../models/student_record_model.dart';
import '../models/uploaded_image_model.dart';

/// 🔌 DATOS — fuente remota del panel administrativo.
/// Habla con `GET/POST /admin/*` del server Node adjuntando el JWT de
/// Supabase del admin (el backend valida el rol "admin").
class AdminRemoteDataSource {
  AdminRemoteDataSource(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  Future<AdminStatsModel> fetchStats() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/stats',
        options: _authOptions,
      );
      return AdminStatsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar las estadísticas');
    }
  }

  Future<List<StudentRecordModel>> fetchStudents() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/students',
        options: _authOptions,
      );
      final rows = response.data as List<dynamic>;
      return rows
          .map(
            (row) => StudentRecordModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar los estudiantes');
    }
  }

  Future<List<AdminUserRecordModel>> fetchUsers() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/users',
        options: _authOptions,
      );
      final rows = response.data as List<dynamic>;
      return rows
          .map(
            (row) => AdminUserRecordModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar los usuarios');
    }
  }

  /// Carritos abandonados (`GET /admin/carts`): ítems que usuarios
  /// dejaron en su carrito sin completar la compra.
  Future<List<AbandonedCartItemModel>> fetchAbandonedCarts() async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/carts',
        options: _authOptions,
      );
      final rows = response.data as List<dynamic>;
      return rows
        .map(
          (row) => AbandonedCartItemModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar los carritos');
    }
  }

  /// Pagos del panel (`GET /admin/payments?status=...`); por defecto
  /// el backend devuelve la cola de pendientes de aprobación.
  Future<List<PaymentRecordModel>> fetchPayments({String? status}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/payments',
        queryParameters: {'status': ?status},
        options: _authOptions,
      );
      final rows = response.data as List<dynamic>;
      return rows
        .map((row) => PaymentRecordModel.fromJson(row as Map<String, dynamic>))
        .toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar los pagos');
    }
  }

  /// Decisión MANUAL del admin (`PATCH /admin/payments/:id`).
  /// Al aprobar, el backend pasa la inscripción a 'approved' y el
  /// estudiante gana ACCESO al curso; al rechazar, lo pierde.
  Future<void> patchPaymentDecision(
    String paymentId, {
    required bool approve,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/admin/payments/$paymentId',
        data: {'action': approve ? 'approve' : 'reject'},
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo registrar la decisión del pago');
    }
  }

  /// Participantes de un curso (`GET /admin/courses/:id/participants`).
  Future<CourseParticipantsModel> fetchCourseParticipants(
    String courseId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/courses/$courseId/participants',
        options: _authOptions,
      );
      return CourseParticipantsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudieron cargar los participantes');
    }
  }

  /// Perfil del estudiante + sus inscripciones (`GET /admin/students/:id`).
  Future<StudentProfileModel> fetchStudentProfile(String id) async {
    try {
      final response = await _dio.get<dynamic>(
        '/admin/students/$id',
        options: _authOptions,
      );
      return StudentProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cargar el perfil del estudiante');
    }
  }

  /// Perfil PROPIO (`GET /me/profile`): datos + inscripciones del
  /// usuario de la sesión (pantalla "Mi perfil", sin permisos admin).
  Future<StudentProfileModel> fetchMyProfile() async {
    try {
      final response = await _dio.get<dynamic>(
        '/me/profile',
        options: _authOptions,
      );
      return StudentProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cargar tu perfil');
    }
  }

  /// Quitar/restaurar el ACCESO a un curso
  /// (`PATCH /admin/students/:studentId/enrollments/:courseId`).
  /// [revoke] true deja la inscripción en 'revoked' (sin acceso);
  /// false la vuelve a 'approved'.
  Future<void> patchEnrollmentAccess({
    required String studentId,
    required String courseId,
    required bool revoke,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/admin/students/$studentId/enrollments/$courseId',
        data: {'action': revoke ? 'revoke' : 'restore'},
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cambiar el acceso al curso');
    }
  }

  /// Sube la imagen (multipart, campo "image") al bucket público
  /// "courses" y devuelve su URL pública.
  Future<UploadedImageModel> uploadImage({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<dynamic>(
        '/admin/upload-image',
        data: form,
        options: _authOptions,
      );
      return UploadedImageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo subir la imagen');
    }
  }

  Future<CategoryModel> createCategory(String name, String slug) async {
    try {
      final response = await _dio.post<dynamic>(
        '/admin/categories',
        data: {'name': name, 'slug': slug},
        options: _authOptions,
      );
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo crear la categoría');
    }
  }

  /// Renombra una categoría (`PATCH /admin/categories/:id`).
  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String slug,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/admin/categories/$id',
        data: {'name': name, 'slug': slug},
        options: _authOptions,
      );
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo actualizar la categoría');
    }
  }

  /// Edita un usuario (`PATCH /admin/users/:id`): perfil, rol y estado.
  /// [isActive] false = desactiva el acceso (borrado lógico; la cuenta
  /// y sus datos nunca se eliminan de la BD).
  Future<AdminUserRecordModel> updateUser({
    required String id,
    required String fullName,
    String? phone,
    required String role,
    required bool isActive,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/admin/users/$id',
        data: {
          'fullName': fullName,
          'phone': phone,
          'role': role,
          'isActive': isActive,
        },
        options: _authOptions,
      );
      return AdminUserRecordModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo actualizar el usuario');
    }
  }

  Future<CreatedUserModel> createUser(NewAdminUser input) async {
    try {
      final response = await _dio.post<dynamic>(
        '/admin/users',
        data: {
          'email': input.email,
          'password': input.password,
          'fullName': input.fullName,
          'phone': input.phone,
          'role': input.role,
        },
        options: _authOptions,
      );
      final model = CreatedUserModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      // La API siempre devuelve el email; si viniera vacío usamos el pedido.
      return model.email.isEmpty
          ? CreatedUserModel(id: model.id, email: input.email)
          : model;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo crear el usuario');
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

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => AdminRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  ),
);
