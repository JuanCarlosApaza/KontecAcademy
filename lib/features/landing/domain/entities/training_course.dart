import 'package:equatable/equatable.dart';

/// Curso de capacitación del catálogo (entidad pura de dominio).
///
/// No conoce JSON ni Flutter: los textos y colores de presentación
/// (badge, degradado del cover, "En vivo – ...", puntos destacados)
/// viven en la capa de presentación (`course_display.dart`).
class TrainingCourse extends Equatable {
  const TrainingCourse({
    required this.id,
    required this.title,
    required this.modality,
    this.imageUrl,
    this.categoryId,
    this.category = 'BIM',
    this.description = '',
    this.hours = 40,
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

  /// Código de la BD: 'live' | 'asynchronous'. El texto visible lo
  /// resuelve la presentación (`modalityLabel`).
  final String modality;

  /// Portada real del curso (`image_url` en la BD). Si es null o no
  /// carga, la UI usa su degradado placeholder como fallback.
  final String? imageUrl;

  /// Id de la categoría en la BD (para editar el curso en el panel).
  final String? categoryId;

  /// Categoría para filtrar en la pantalla de capacitaciones
  /// (ej: "BIM", "MEP", "Civil 3D", "Revit", "VDC").
  final String category;

  /// Descripción larga (pantalla de detalle).
  final String description;

  /// Duración en horas (pantalla de detalle).
  final int hours;

  /// Duración en semanas (null = no definida; sección de la plantilla).
  final int? totalWeeks;

  /// Precio general en USD (0 = sin precio cargado).
  final double price;

  /// Precio de OFERTA en USD (null = sin descuento).
  ///
  /// La UI lo pinta junto a [price] TACHADO: el usuario paga el de
  /// oferta y ve cuánto se ahorra. Ver `offerPrice`/`effectivePrice`
  /// en la extensión de presentación para la regla de validez.
  final double? compareAtPrice;

  /// Estado del curso en la BD: 'draft' | 'upcoming' | 'active' | 'inactive'.
  /// La UI pública solo muestra 'active'; el panel admin los lista todos.
  final String status;

  /// Secciones de texto de la plantilla de landing (null = aún sin contenido).
  final String? professorBio;
  final String? teachingMethod;

  /// Una opción por línea (la UI la pinta como viñetas).
  final String? targetAudience;
  final String? certificateInfo;

  /// Una opción por línea (la UI la pinta como lista).
  final String? careerOpportunities;

  @override
  List<Object?> get props => [
    id,
    title,
    modality,
    imageUrl,
    categoryId,
    category,
    hours,
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
