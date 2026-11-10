import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_repository.dart';

/// Parámetros de [SetEnrollmentAccess].
class SetEnrollmentAccessParams {
  const SetEnrollmentAccessParams({
    required this.studentId,
    required this.courseId,
    required this.revoke,
  });

  final String studentId;
  final String courseId;

  /// true = quitar acceso (inscripción → 'revoked');
  /// false = restaurarlo (→ 'approved').
  final bool revoke;
}

/// Caso de uso: quitar o restaurar el ACCESO de un estudiante a un
/// curso (cambia el estado de su inscripción). No toca el pago.
class SetEnrollmentAccess
    extends UseCase<(bool, Failure?), SetEnrollmentAccessParams> {
  SetEnrollmentAccess(this._repository);

  final AdminRepository _repository;

  @override
  Future<(bool, Failure?)> call(SetEnrollmentAccessParams params) =>
      _repository.setEnrollmentAccess(
        studentId: params.studentId,
        courseId: params.courseId,
        revoke: params.revoke,
      );
}
