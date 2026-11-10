import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';

/// Modelo de la categoría: único lugar del feature que conoce su JSON.
class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
  );

  Category toEntity() => Category(id: id, name: name, slug: slug);

  @override
  List<Object?> get props => [id, name, slug];
}
