import 'package:equatable/equatable.dart';

/// Confirmación devuelta por el backend tras crear la inscripción.
class CheckoutResult extends Equatable {
  const CheckoutResult({
    required this.enrollmentIds,
    required this.paymentIds,
    required this.total,
  });

  /// IDs de las filas creadas en `enrollments` (status pending_payment).
  final List<String> enrollmentIds;

  /// IDs de los pagos registrados (status pending_approval).
  final List<String> paymentIds;

  /// Monto total registrado en USD.
  final double total;

  @override
  List<Object?> get props => [enrollmentIds, paymentIds, total];
}
