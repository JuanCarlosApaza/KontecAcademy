import 'package:equatable/equatable.dart';

import '../../domain/entities/membership_plan.dart';

/// Modelo de plan de membresía (`GET /membership-plans`).
/// Único lugar del feature que conoce su JSON.
class MembershipPlanModel extends Equatable {
  const MembershipPlanModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.months,
    required this.price,
    this.isActive = true,
    this.sortOrder = 0,
    this.imageUrl,
  });

  final String id;
  final String slug;
  final String name;
  final int months;
  final double price;
  final bool isActive;
  final int sortOrder;
  final String? imageUrl;

  factory MembershipPlanModel.fromJson(Map<String, dynamic> json) =>
      MembershipPlanModel(
        id: json['id'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        months: (json['months'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl'] as String?,
      );

  MembershipPlan toEntity() => MembershipPlan(
    id: id,
    slug: slug,
    name: name,
    months: months,
    price: price,
    isActive: isActive,
    sortOrder: sortOrder,
    imageUrl: imageUrl,
  );

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    months,
    price,
    isActive,
    imageUrl,
  ];
}
