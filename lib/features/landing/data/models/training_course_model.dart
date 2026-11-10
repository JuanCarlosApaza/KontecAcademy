import 'package:equatable/equatable.dart';

import '../../domain/entities/training_course.dart';

/// Modelo de curso del catálogo.
///
/// Único lugar del feature que conoce el JSON de la API REST
/// (camelCase: `totalHours`, `category: {id,name,slug}`, `modality`, ...).
class TrainingCourseModel extends Equatable {
  const TrainingCourseModel({
    required this.id,
    required this.title,
    required this.modality,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.totalHours = 0,
    this.totalWeeks,
    this.price = 0,
    this.compareAtPrice,
    this.status = 'active',
    this.professorBio,
    this.teachingMethod,
    this.targetAudience,
    this.certificateInfo,
    this.careerOpportunities,
  });

  final String id;
  final String title;
  final String? description;

  /// Portada real del curso (null si la BD no tiene imagen).
  final String? imageUrl;

  /// Id de la categoría (para editar el curso en el panel admin).
  final String? categoryId;

  /// Nombre de la categoría embebida en la respuesta (`category.name`).
  final String? categoryName;

  /// Código crudo de la API: 'asynchronous' | 'live'.
  final String modality;

  final int totalHours;
  final int? totalWeeks;
  final double price;

  /// Precio de oferta en USD (null = sin descuento).
  final double? compareAtPrice;

  /// Estado en la BD: 'draft' | 'upcoming' | 'active' | 'inactive'.
  final String status;

  /// Secciones de la plantilla de landing (null = sin contenido).
  final String? professorBio;
  final String? teachingMethod;
  final String? targetAudience;
  final String? certificateInfo;
  final String? careerOpportunities;

  factory TrainingCourseModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return TrainingCourseModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: category?['name'] as String?,
      modality: json['modality'] as String? ?? 'asynchronous',
      totalHours: (json['totalHours'] as num?)?.toInt() ?? 0,
      totalWeeks: (json['totalWeeks'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      professorBio: json['professorBio'] as String?,
      teachingMethod: json['teachingMethod'] as String?,
      targetAudience: json['targetAudience'] as String?,
      certificateInfo: json['certificateInfo'] as String?,
      careerOpportunities: json['careerOpportunities'] as String?,
    );
  }

  /// Convierte a entidad de dominio (la UI solo ve entidades).
  TrainingCourse toEntity() => TrainingCourse(
    id: id,
    title: title,
    modality: modality,
    imageUrl: imageUrl,
    categoryId: categoryId,
    category: categoryName ?? '',
    description: description ?? '',
    hours: totalHours,
    totalWeeks: totalWeeks,
    price: price,
    compareAtPrice: compareAtPrice,
    status: status,
    professorBio: professorBio,
    teachingMethod: teachingMethod,
    targetAudience: targetAudience,
    certificateInfo: certificateInfo,
    careerOpportunities: careerOpportunities,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    categoryName,
    modality,
    totalHours,
    price,
    status,
  ];
}
