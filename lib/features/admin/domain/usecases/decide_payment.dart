import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_repository.dart';

/// Parámetros de [DecidePayment].
class DecidePaymentParams {
  const DecidePaymentParams({required this.paymentId, required this.approve});

  final String paymentId;

  /// true = aprueba (el estudiante gana acceso al curso);
  /// false = rechaza (pierde el acceso).
  final bool approve;
}

/// Caso de uso: decisión MANUAL del admin sobre un pago. El comprobante
/// se verifica fuera del sistema (Yape/banco); aquí solo se registra:
/// al aprobar, la inscripción pasa a 'approved' y el estudiante gana
/// ACCESO al curso ("Mis cursos").
class DecidePayment extends UseCase<(bool, Failure?), DecidePaymentParams> {
  DecidePayment(this._repository);

  final AdminRepository _repository;

  @override
  Future<(bool, Failure?)> call(DecidePaymentParams params) =>
      _repository.decidePayment(
        paymentId: params.paymentId,
        approve: params.approve,
      );
}
