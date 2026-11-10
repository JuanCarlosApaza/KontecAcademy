import 'package:equatable/equatable.dart';

import '../../domain/entities/abandoned_cart_item.dart';

/// DTO del carrito abandonado del panel admin
/// (`GET /admin/carts`). Único lugar del feature que conoce su JSON;
/// la UI solo ve la entidad [AbandonedCartItem].
class AbandonedCartItemModel extends Equatable {
  const AbandonedCartItemModel({
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
  final double price;
  final String addedAt;

  factory AbandonedCartItemModel.fromJson(Map<String, dynamic> json) =>
      AbandonedCartItemModel(
        userId: json['userId'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        addedAt: json['addedAt'] as String? ?? '',
      );

  /// Traduce a entidad de dominio (mapper).
  AbandonedCartItem toEntity() => AbandonedCartItem(
    userId: userId,
    email: email,
    fullName: fullName,
    courseId: courseId,
    title: title,
    price: price,
    addedAt: DateTime.tryParse(addedAt),
  );

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
