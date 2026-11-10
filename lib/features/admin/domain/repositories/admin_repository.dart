import '../../../../core/error/failures.dart';
import '../../../landing/domain/entities/category.dart';
import '../entities/abandoned_cart_item.dart';
import '../entities/admin_stats.dart';
import '../entities/admin_user_record.dart';
import '../entities/course_participant.dart';
import '../entities/created_user.dart';
import '../entities/new_admin_user.dart';
import '../entities/payment_record.dart';
import '../entities/student_profile.dart';
import '../entities/student_record.dart';

/// Contrato del panel administrativo (dominio).
///
/// Implementación (data): llama a `GET /admin/*` y `POST /admin/*` de
/// la API Node con el JWT del usuario; el backend exige rol "admin".
abstract class AdminRepository {
  Future<(AdminStats, Failure?)> getStats();
  Future<(List<StudentRecord>, Failure?)> getStudents();

  /// Todos los usuarios + roles (sección "Usuarios").
  Future<(List<AdminUserRecord>, Failure?)> getUsers();

  Future<(Category, Failure?)> createCategory(String name, String slug);

  /// Renombra una categoría (borrado lógico no aplica: no tiene estado).
  /// [slug] llega ya resuelto por el caso de uso.
  Future<(Category, Failure?)> updateCategory({
    required String id,
    required String name,
    required String slug,
  });

  Future<(CreatedUser, Failure?)> createAdminUser(NewAdminUser input);

  /// Edita perfil, rol y estado de un usuario. [isActive] false =
  /// desactiva el acceso SIN borrar ningún dato de la BD.
  Future<(AdminUserRecord, Failure?)> updateUser({
    required String id,
    required String fullName,
    String? phone,
    required String role,
    required bool isActive,
  });

  /// Sube una imagen local al bucket público "courses" de Supabase
  /// Storage y devuelve la URL pública (para courses.image_url).
  Future<(String, Failure?)> uploadImage({
    required List<int> bytes,
    required String filename,
    required String contentType,
  });

  /// Carritos abandonados: ítems que usuarios dejaron en su carrito
  /// sin completar la compra (addedAt desc).
  Future<(List<AbandonedCartItem>, Failure?)> getAbandonedCarts();

  /// Pagos del panel filtrados por estado; la cola por defecto es
  /// 'pending_approval' (pagos que esperan aprobación de ticket).
  Future<(List<PaymentRecord>, Failure?)> getPayments(String status);

  /// Decisión manual del admin sobre un pago. [approve] true = aprueba
  /// (el estudiante gana ACCESO al curso); false = rechaza (lo pierde).
  Future<(bool, Failure?)> decidePayment({
    required String paymentId,
    required bool approve,
  });

  // ── PARTICIPANTES + PERFIL DEL ESTUDIANTE ────────────────────

  /// Participantes de un curso (inscripción + datos), con su título.
  Future<(CourseParticipants, Failure?)> getCourseParticipants(
    String courseId,
  );

  /// Perfil del estudiante + sus inscripciones.
  Future<(StudentProfile, Failure?)> getStudentProfile(String id);

  /// Perfil PROPIO del usuario de la sesión (`GET /me/profile`).
  Future<(StudentProfile, Failure?)> getMyProfile();

  /// Quitar/restaurar el ACCESO a un curso. [revoke] true deja la
  /// inscripción en 'revoked' (sin acceso); false la vuelve 'approved'.
  /// No toca el registro de pago.
  Future<(bool, Failure?)> setEnrollmentAccess({
    required String studentId,
    required String courseId,
    required bool revoke,
  });
}
