import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../entities/checkout_data.dart';
import '../entities/checkout_result.dart';
import '../repositories/checkout_repository.dart';

/// Caso de uso: confirmar la inscripción con los datos personales.
///
/// Regla de negocio: el carrito no puede estar vacío.
class CreateEnrollment
    extends UseCase<(CheckoutResult, Failure?), CreateEnrollmentParams> {
  CreateEnrollment(this._repository);

  final CheckoutRepository _repository;

  @override
  Future<(CheckoutResult, Failure?)> call(CreateEnrollmentParams params) {
    if (params.items.isEmpty) {
      return Future.value((
        const CheckoutResult(enrollmentIds: [], paymentIds: [], total: 0),
        const UnknownFailure('El carrito está vacío.'),
      ));
    }
    return _repository.enroll(items: params.items, data: params.data);
  }
}

class CreateEnrollmentParams {
  const CreateEnrollmentParams({required this.items, required this.data});

  final List<CartItem> items;
  final CheckoutData data;
}
