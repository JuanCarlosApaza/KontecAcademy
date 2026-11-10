import '../../../../core/usecase/usecase.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

/// Entrada de [SaveCart]: propietario + items a persistir.
class SaveCartParams {
  const SaveCartParams({required this.ownerId, required this.items});

  final String ownerId;
  final List<CartItem> items;
}

/// Caso de uso: persistir el carrito completo del propietario.
class SaveCart extends UseCase<void, SaveCartParams> {
  SaveCart(this._repository);

  final CartRepository _repository;

  @override
  Future<void> call(SaveCartParams params) =>
      _repository.save(params.ownerId, params.items);
}
