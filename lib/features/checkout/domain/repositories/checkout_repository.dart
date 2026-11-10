import '../../../../core/error/failures.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../entities/checkout_data.dart';
import '../entities/checkout_result.dart';

/// Contrato de checkout (dominio).
///
/// Implementación (data): llama a `POST /checkout` de la API Node con
/// el JWT del usuario; el backend usa la service_role para escribir en
/// `users`, `enrollments` y `payments` (el front NUNCA ve esa clave).
abstract class CheckoutRepository {
  Future<(CheckoutResult, Failure?)> enroll({
    required List<CartItem> items,
    required CheckoutData data,
  });
}
