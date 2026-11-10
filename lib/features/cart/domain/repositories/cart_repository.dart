import '../entities/cart_item.dart';

/// Contrato de persistencia del carrito (dominio).
///
/// El carrito es POR USUARIO: [ownerId] es el id del usuario con
/// sesión; 'guest' cuando no hay sesión. Así cada cuenta tiene su
/// propio carrito en el mismo dispositivo/navegador (nunca se mezclan
/// los cursos de dos usuarios distintos).
abstract class CartRepository {
  Future<List<CartItem>> load(String ownerId);
  Future<void> save(String ownerId, List<CartItem> items);
}
