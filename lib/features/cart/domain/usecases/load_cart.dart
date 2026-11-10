import '../../../../core/usecase/usecase.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

/// Caso de uso: cargar el carrito persistido de un propietario.
///
/// [ownerId] es el id del usuario con sesión o 'guest' sin ella
/// (cada cuenta tiene su propio carrito).
class LoadCart extends UseCase<List<CartItem>, String> {
  LoadCart(this._repository);

  final CartRepository _repository;

  @override
  Future<List<CartItem>> call(String ownerId) => _repository.load(ownerId);
}
