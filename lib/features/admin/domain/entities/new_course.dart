import 'package:equatable/equatable.dart';

/// Datos para crear un curso (payload del formulario admin).
class NewCourse extends Equatable {
  const NewCourse({
    required this.title,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.modality = 'asynchronous',
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

  final String title;
  final String? description;
  final String? imageUrl;
  final String? categoryId;

  /// 'asynchronous' | 'live' (código que entiende la API).
  final String modality;

  final int totalHours;
  final int? totalWeeks;
  final double price;
  final double? compareAtPrice;

  /// 'draft' | 'upcoming' | 'active' | 'inactive'.
  final String status;

  /// Secciones de texto de la plantilla de landing.
  final String? professorBio;
  final String? teachingMethod;
  final String? targetAudience;
  final String? certificateInfo;
  final String? careerOpportunities;

  @override
  List<Object?> get props => [
    title,
    description,
    imageUrl,
    categoryId,
    modality,
    totalHours,
    totalWeeks,
    price,
    compareAtPrice,
    status,
    professorBio,
    teachingMethod,
    targetAudience,
    certificateInfo,
    careerOpportunities,
  ];
}
