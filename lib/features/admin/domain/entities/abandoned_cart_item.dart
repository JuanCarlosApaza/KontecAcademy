import 'package:equatable/equatable.dart';

/// Ítem que un usuario dejó en su carrito sin completar la compra
/// (carrito abandonado, visible para el panel administrativo).
class AbandonedCartItem extends Equatable {
  const AbandonedCartItem({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.courseId,
    required this.title,
    required this.price,
    required this.addedAt,
  });

  final String userId;
  final String email;
  final String fullName;
  final String courseId;
  final String title;

  /// Precio del curso AL MOMENTO de consultar (no el de cuando se
  /// agregó): el servidor siempre resuelve el precio vigente.
  final double price;

  /// Cuándo se agregó al carrito.
  final DateTime? addedAt;

  @override
  List<Object?> get props => [
    userId,
    email,
    fullName,
    courseId,
    title,
    price,
    addedAt,
  ];
}
