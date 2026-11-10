import 'package:equatable/equatable.dart';

/// Categoría del catálogo (chips de filtro en Capacitaciones).
class Category extends Equatable {
  const Category({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  @override
  List<Object?> get props => [id, name, slug];
}
