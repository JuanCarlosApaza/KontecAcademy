import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/abandoned_cart_item.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: carritos abandonados (ítems que usuarios dejaron en su
/// carrito sin completar la compra) — sección "Pagos y carritos".
class ListAbandonedCarts
    extends UseCase<(List<AbandonedCartItem>, Failure?), NoParams> {
  ListAbandonedCarts(this._repository);

  final AdminRepository _repository;

  @override
  Future<(List<AbandonedCartItem>, Failure?)> call(NoParams params) =>
      _repository.getAbandonedCarts();
}
