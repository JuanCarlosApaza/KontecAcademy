import 'package:equatable/equatable.dart';

/// Ítem dentro del carrito de compras (curso o ruta/combo).
///
/// Entidad pura: guarda solo lo mínimo para pintar el carrito y cobrar
/// (el precio se congela al agregar para que no cambie mientras el
/// usuario navega). Para una ruta, `price` es el precio del combo YA
/// con el % de rebaja aplicado.
class CartItem extends Equatable {
  const CartItem({
    required this.courseId,
    required this.title,
    required this.price,
    this.type = 'course',
    this.modality = '',
    this.imageUrl,
  });

  /// id del curso (o de la ruta si [type] == 'path') en la BD.
  final String courseId;
  final String title;

  /// Precio en USD al momento de agregarlo.
  final double price;

  /// 'course' (default) | 'path' — combo con descuento.
  final String type;

  /// Ej: "Asíncrono – Pregrabado".
  final String modality;
  final String? imageUrl;

  bool get isPath => type == 'path';

  /// Membresía (plan de acceso total a los cursos).
  bool get isMembership => type == 'membership';

  @override
  List<Object?> get props => [courseId, title, price, type, modality, imageUrl];
}

/// Regla de negocio única: el total del carrito es la suma de los
/// precios de sus ítems (precio congelado al agregar). Toda la UI y
/// los viewmodels deben leer `totalPrice` en vez de reimplementar la
/// suma.
extension CartItemsTotal on List<CartItem> {
  double get totalPrice => fold(0, (sum, item) => sum + item.price);
}
