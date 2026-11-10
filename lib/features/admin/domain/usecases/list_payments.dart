import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_record.dart';
import '../repositories/admin_repository.dart';

/// Parámetros de [ListPayments]: el estado a filtrar
/// ('pending_approval' | 'approved' | 'rejected').
class ListPaymentsParams {
  const ListPaymentsParams({required this.status});

  final String status;
}

/// Caso de uso: pagos del panel filtrados por estado — sección
/// "Pagos y carritos" (cola por defecto: pendientes de aprobación).
class ListPayments
    extends UseCase<(List<PaymentRecord>, Failure?), ListPaymentsParams> {
  ListPayments(this._repository);

  final AdminRepository _repository;

  @override
  Future<(List<PaymentRecord>, Failure?)> call(ListPaymentsParams params) =>
      _repository.getPayments(params.status);
}
