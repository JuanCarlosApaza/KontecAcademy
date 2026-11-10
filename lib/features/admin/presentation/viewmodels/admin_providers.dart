import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../admin_injector.dart';
import '../../domain/entities/abandoned_cart_item.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/admin_user_record.dart';
import '../../domain/entities/course_participant.dart';
import '../../domain/entities/new_admin_user.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/entities/roles_matrix.dart';
import '../../domain/entities/session_access.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/entities/student_record.dart';

/// Sesión del panel: roles + permisos del usuario (`GET /me` vía
/// GetSessionAccess).
///
/// Vacío si no hay sesión o la llamada falla (fail-closed: sin
/// respuesta confiable no se otorgan permisos).
final sessionAccessProvider = FutureProvider<SessionAccess>((ref) async {
  // Reacciona a login/logout: sin este watch el token quedaría congelado.
  ref.watch(accessTokenProvider);

  final (access, _) = await ref.watch(getSessionAccessProvider)(NoParams());
  return access;
});

/// ¿Tiene el permiso [code]? Sin respuesta aún → false (fail-closed).
final permissionProvider = Provider.family<bool, String>((ref, code) {
  return ref.watch(sessionAccessProvider).value?.hasPermission(code) ?? false;
});

/// ¿Puede entrar al panel? (cualquier permiso habilita una sección;
/// el rol admin recibe el catálogo completo desde el backend).
final canEnterAdminPanelProvider = Provider<bool>((ref) {
  return ref.watch(sessionAccessProvider).value?.hasAnyPermission ?? false;
});

/// Roles del usuario actual (derivado de [sessionAccessProvider]).
final adminRolesProvider = FutureProvider<List<String>>((ref) async {
  final access = await ref.watch(sessionAccessProvider.future);
  return access.roles;
});

/// ¿El usuario tiene rol "admin"? (el menú "ADMIN" del landing)
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(sessionAccessProvider).value?.isAdmin ?? false;
});

/// Matriz rol × permiso para la pantalla /admin/roles.
///
/// Reacciona al login/logout y a los cambios guardados (se invalida
/// tras un PUT/POST/DELETE para refrescar la tabla).
final rolesMatrixProvider = FutureProvider<RolesMatrix>((ref) async {
  ref.watch(accessTokenProvider);

  final (matrix, failure) = await ref.watch(getRolesMatrixProvider)(
    NoParams(),
  );
  if (failure != null || matrix == null) {
    throw failure ?? UnknownFailure('No se pudieron cargar los roles');
  }
  return matrix;
});

/// STATE del panel administrativo (KPIs + estudiantes + usuarios +
/// formularios + subida de imágenes).
class AdminPanelState {
  const AdminPanelState({
    this.stats,
    this.students = const [],
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.isUploadingImage = false,
    this.successMessage,
    this.submitError,
  });

  final AdminStats? stats;
  final List<StudentRecord> students;
  final List<AdminUserRecord> users;
  final bool isLoading;
  final String? error;

  final bool isSubmitting;
  final bool isUploadingImage;
  final String? successMessage;
  final String? submitError;

  AdminPanelState copyWith({
    AdminStats? stats,
    List<StudentRecord>? students,
    List<AdminUserRecord>? users,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
    bool? isUploadingImage,
    String? successMessage,
    String? submitError,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSubmitError = false,
  }) {
    return AdminPanelState(
      stats: stats ?? this.stats,
      students: students ?? this.students,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }
}

/// ViewModel (MVVM) del panel: carga KPIs y estudiantes, y ejecuta las
/// altas de categorías y usuarios.
class AdminViewModel extends Notifier<AdminPanelState> {
  @override
  AdminPanelState build() => const AdminPanelState();

  /// Carga KPIs, estudiantes y usuarios EN PARALELO.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final statsFuture = ref.read(getAdminStatsProvider)(NoParams());
    final studentsFuture = ref.read(getStudentsProvider)(NoParams());
    final usersFuture = ref.read(getAdminUsersProvider)(NoParams());

    final (stats, statsFailure) = await statsFuture;
    final (students, studentsFailure) = await studentsFuture;
    final (users, usersFailure) = await usersFuture;

    final failure = statsFailure ?? studentsFailure ?? usersFailure;
    state = state.copyWith(
      isLoading: false,
      stats: statsFailure == null ? stats : state.stats,
      students: studentsFailure == null ? students : state.students,
      users: usersFailure == null ? users : state.users,
      error: failure?.message,
    );
  }

  /// Sube una imagen local al bucket "courses" y devuelve su URL
  /// pública (para el campo "Imagen" del formulario de cursos).
  Future<String?> uploadImage({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    state = state.copyWith(isUploadingImage: true, clearSubmitError: true);

    final (url, failure) = await ref.read(uploadCourseImageProvider)(
      UploadCourseImageParams(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    state = state.copyWith(isUploadingImage: false);
    if (failure != null) {
      state = state.copyWith(submitError: failure.message);
      return null;
    }
    return url;
  }

  /// Crea una categoría. Devuelve true si salió bien.
  Future<bool> createCategory(String name) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      clearSuccess: true,
    );

    final (category, failure) = await ref.read(createCategoryProvider)(
      CreateCategoryParams(name: name),
    );

    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    state = state.copyWith(
      isSubmitting: false,
      successMessage: 'Categoría "${category.name}" creada ✅',
    );
    return true;
  }

  /// Crea un usuario (auth + perfil + rol). Devuelve true si salió bien.
  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'student',
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      clearSuccess: true,
    );

    final (user, failure) = await ref.read(createAdminUserProvider)(
      CreateAdminUserParams(
        input: NewAdminUser(
          email: email.trim(),
          password: password,
          fullName: fullName.trim(),
          phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
          role: role,
        ),
      ),
    );

    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    state = state.copyWith(
      isSubmitting: false,
      successMessage: 'Usuario ${user.email} creado ✅',
    );
    await load();
    return true;
  }

  /// Renombra una categoría. Devuelve true si salió bien.
  Future<bool> updateCategory({
    required String id,
    required String name,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      clearSuccess: true,
    );

    final (category, failure) = await ref.read(updateCategoryProvider)(
      UpdateCategoryParams(id: id, name: name),
    );

    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    state = state.copyWith(
      isSubmitting: false,
      successMessage: 'Categoría actualizada: "${category.name}" ✅',
    );
    return true;
  }

  /// Edita un usuario (perfil, rol y estado). [isActive] false =
  /// desactiva el acceso sin borrar ningún dato de la BD.
  Future<bool> updateUser({
    required String id,
    required String fullName,
    String? phone,
    required String role,
    required bool isActive,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      clearSuccess: true,
    );

    final (user, failure) = await ref.read(updateUserProvider)(
      UpdateUserParams(
        id: id,
        fullName: fullName,
        phone: phone,
        role: role,
        isActive: isActive,
      ),
    );

    if (failure != null) {
      state = state.copyWith(isSubmitting: false, submitError: failure.message);
      return false;
    }

    state = state.copyWith(
      isSubmitting: false,
      successMessage: 'Usuario ${user.email} actualizado ✅',
    );
    await load();
    return true;
  }

  void clearMessages() {
    if (state.successMessage != null || state.submitError != null) {
      state = state.copyWith(clearSuccess: true, clearSubmitError: true);
    }
  }
}

final adminViewModelProvider =
    NotifierProvider<AdminViewModel, AdminPanelState>(AdminViewModel.new);

/// Carritos abandonados (`GET /admin/carts`): ítems que los usuarios
/// dejaron en su carrito sin completar la compra. Sección "Pagos y
/// carritos"; reacciona al login (mismo patrón que adminRolesProvider).
final abandonedCartsProvider =
    FutureProvider<List<AbandonedCartItem>>((ref) async {
      // Reacciona a login/logout: sin este watch el token quedaría congelado.
      ref.watch(accessTokenProvider);

      final (carts, _) = await ref.watch(listAbandonedCartsProvider)(
        NoParams(),
      );
      return carts;
    });

/// Pagos del panel por estado (family: 'pending_approval' |
/// 'approved' | 'rejected'), para el filtro de "Pagos y carritos".
final paymentsProvider =
    FutureProvider.family<List<PaymentRecord>, String>((ref, status) async {
      ref.watch(accessTokenProvider);

      final (payments, _) = await ref.watch(listPaymentsProvider)(
        ListPaymentsParams(status: status),
      );
      return payments;
    });

/// Participantes de un curso (family: courseId). Sección "Participantes".
final participantsProvider =
    FutureProvider.family<CourseParticipants, String>((ref, courseId) async {
      ref.watch(accessTokenProvider);

      final (data, _) = await ref.watch(listCourseParticipantsProvider)(
        courseId,
      );
      return data;
    });

/// Perfil de un estudiante + sus inscripciones (family: studentId).
final studentProfileProvider =
    FutureProvider.family<StudentProfile, String>((ref, id) async {
      ref.watch(accessTokenProvider);

      final (profile, _) = await ref.watch(getStudentProfileProvider)(id);
      return profile;
    });

/// Perfil PROPIO del usuario de la sesión (`GET /me/profile`), para la
/// pantalla "Mi perfil". Reacciona al login/logout.
final myProfileProvider = FutureProvider<StudentProfile>((ref) async {
  ref.watch(accessTokenProvider);

  final (profile, _) = await ref.watch(getMyProfileProvider)(NoParams());
  return profile;
});
