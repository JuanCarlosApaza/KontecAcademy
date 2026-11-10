import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item.dart';

/// DTO del ítem del carrito persistido en el dispositivo
/// (SharedPreferences: JSON con courseId, title, price, modality,
/// imageUrl).
///
/// Único lugar del feature que conoce ese JSON.
class CartItemModel extends Equatable {
  const CartItemModel({
    required this.courseId,
    required this.title,
    required this.price,
    this.type = 'course',
    this.modality = '',
    this.imageUrl,
  });

  final String courseId;
  final String title;
  final double price;
  final String type;
  final String modality;
  final String? imageUrl;

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    courseId: json['courseId'] as String,
    title: json['title'] as String,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    // Datos locales viejos no traen 'type' → curso (compat).
    type: (json['type'] as String?) ?? 'course',
    modality: (json['modality'] as String?) ?? '',
    imageUrl: json['imageUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'title': title,
    'price': price,
    'type': type,
    'modality': modality,
    'imageUrl': imageUrl,
  };

  /// Traduce a entidad de dominio (mapper).
  CartItem toEntity() => CartItem(
    courseId: courseId,
    title: title,
    price: price,
    type: type,
    modality: modality,
    imageUrl: imageUrl,
  );

  /// Traductor inverso: entidad → DTO (para persistir).
  factory CartItemModel.fromEntity(CartItem item) => CartItemModel(
    courseId: item.courseId,
    title: item.title,
    price: item.price,
    type: item.type,
    modality: item.modality,
    imageUrl: item.imageUrl,
  );

  @override
  List<Object?> get props => [courseId, title, price, type, modality, imageUrl];
}
