import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../landing/domain/entities/category.dart';
import '../../domain/entities/abandoned_cart_item.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/admin_user_record.dart';
import '../../domain/entities/course_participant.dart';
import '../../domain/entities/created_user.dart';
import '../../domain/entities/new_admin_user.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/entities/student_record.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

/// Implementación concreta del repositorio del panel admin.
///
/// Traduce excepciones (`data`) en fallas (`domain`). El token se toma
/// de la sesión actual en cada petición (se refresca solo).
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider)),
);

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<(AdminStats, Failure?)> getStats() async {
    try {
      final model = await _remote.fetchStats();
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        const AdminStats(),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (const AdminStats(), NetworkFailure(e.message));
    } catch (e) {
      return (const AdminStats(), UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<StudentRecord>, Failure?)> getStudents() async {
    try {
      final models = await _remote.fetchStudents();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on ServerException catch (e) {
      return (
        <StudentRecord>[],
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (<StudentRecord>[], NetworkFailure(e.message));
    } catch (e) {
      return (<StudentRecord>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<AdminUserRecord>, Failure?)> getUsers() async {
    try {
      final models = await _remote.fetchUsers();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on ServerException catch (e) {
      return (
        <AdminUserRecord>[],
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (<AdminUserRecord>[], NetworkFailure(e.message));
    } catch (e) {
      return (<AdminUserRecord>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(String, Failure?)> uploadImage({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      final model = await _remote.uploadImage(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
      return (model.publicUrl, null);
    } on ServerException catch (e) {
      return ('', ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return ('', NetworkFailure(e.message));
    } catch (e) {
      return ('', UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<AbandonedCartItem>, Failure?)> getAbandonedCarts() async {
    try {
      final models = await _remote.fetchAbandonedCarts();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on ServerException catch (e) {
      return (
        <AbandonedCartItem>[],
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (<AbandonedCartItem>[], NetworkFailure(e.message));
    } catch (e) {
      return (<AbandonedCartItem>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<PaymentRecord>, Failure?)> getPayments(String status) async {
    try {
      final models = await _remote.fetchPayments(status: status);
      return (models.map((m) => m.toEntity()).toList(), null);
    } on ServerException catch (e) {
      return (
        <PaymentRecord>[],
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (<PaymentRecord>[], NetworkFailure(e.message));
    } catch (e) {
      return (<PaymentRecord>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> decidePayment({
    required String paymentId,
    required bool approve,
  }) async {
    try {
      await _remote.patchPaymentDecision(paymentId, approve: approve);
      return (true, null);
    } on ServerException catch (e) {
      return (false, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (false, NetworkFailure(e.message));
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(CourseParticipants, Failure?)> getCourseParticipants(
    String courseId,
  ) async {
    try {
      final model = await _remote.fetchCourseParticipants(courseId);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        CourseParticipants(courseId: courseId, courseTitle: ''),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (
        CourseParticipants(courseId: courseId, courseTitle: ''),
        NetworkFailure(e.message),
      );
    } catch (e) {
      return (
        CourseParticipants(courseId: courseId, courseTitle: ''),
        UnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<(StudentProfile, Failure?)> getStudentProfile(String id) async {
    try {
      final model = await _remote.fetchStudentProfile(id);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        StudentProfile(id: id, fullName: '', email: ''),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (StudentProfile(id: id, fullName: '', email: ''), NetworkFailure(e.message));
    } catch (e) {
      return (
        StudentProfile(id: id, fullName: '', email: ''),
        UnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<(StudentProfile, Failure?)> getMyProfile() async {
    try {
      final model = await _remote.fetchMyProfile();
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        const StudentProfile(id: '', fullName: '', email: ''),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (
        const StudentProfile(id: '', fullName: '', email: ''),
        NetworkFailure(e.message),
      );
    } catch (e) {
      return (
        const StudentProfile(id: '', fullName: '', email: ''),
        UnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<(bool, Failure?)> setEnrollmentAccess({
    required String studentId,
    required String courseId,
    required bool revoke,
  }) async {
    try {
      await _remote.patchEnrollmentAccess(
        studentId: studentId,
        courseId: courseId,
        revoke: revoke,
      );
      return (true, null);
    } on ServerException catch (e) {
      return (false, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (false, NetworkFailure(e.message));
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(Category, Failure?)> createCategory(String name, String slug) async {
    try {
      final model = await _remote.createCategory(name, slug);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        Category(id: '', name: name, slug: slug),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (
        Category(id: '', name: name, slug: slug),
        NetworkFailure(e.message),
      );
    } catch (e) {
      return (
        Category(id: '', name: name, slug: slug),
        UnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<(CreatedUser, Failure?)> createAdminUser(NewAdminUser input) async {
    try {
      final model = await _remote.createUser(input);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        CreatedUser(id: '', email: input.email),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (
        CreatedUser(id: '', email: input.email),
        NetworkFailure(e.message),
      );
    } catch (e) {
      return (
        CreatedUser(id: '', email: input.email),
        UnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<(Category, Failure?)> updateCategory({
    required String id,
    required String name,
    required String slug,
  }) async {
    try {
      final model = await _remote.updateCategory(
        id: id,
        name: name.trim(),
        slug: slug,
      );
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        Category(id: id, name: name, slug: slug),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (
        Category(id: id, name: name, slug: slug),
        NetworkFailure(e.message),
      );
    } catch (e) {
      return (
        Category(id: id, name: name, slug: slug),
        UnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<(AdminUserRecord, Failure?)> updateUser({
    required String id,
    required String fullName,
    String? phone,
    required String role,
    required bool isActive,
  }) async {
    try {
      final model = await _remote.updateUser(
        id: id,
        fullName: fullName.trim(),
        phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        role: role,
        isActive: isActive,
      );
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        AdminUserRecord(id: id, email: '', fullName: fullName),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (
        AdminUserRecord(id: id, email: '', fullName: fullName),
        NetworkFailure(e.message),
      );
    } catch (e) {
      return (
        AdminUserRecord(id: id, email: '', fullName: fullName),
        UnknownFailure(e.toString()),
      );
    }
  }
}
