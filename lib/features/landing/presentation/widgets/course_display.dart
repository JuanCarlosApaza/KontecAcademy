import 'package:flutter/material.dart';

import '../../domain/entities/training_course.dart';

/// Datos de PRESENTACIÓN de un curso: textos de marketing y colores.
///
/// Regla de Clean Architecture: la entidad [TrainingCourse] es pura y
/// no importa Flutter; estos valores derivados viven únicamente en la
/// capa de presentación y se resuelven con la extensión.
extension TrainingCourseDisplay on TrainingCourse {
  /// Texto de modalidad para el usuario final.
  String get modalityLabel => modality == 'live'
      ? 'En vivo – Sesiones programadas'
      : 'Asíncrono – Pregrabado';

  /// Etiqueta del badge centrado en el cover.
  String get badge => 'Entrenamiento Especializado';

  /// Degradado placeholder del cover: se usa mientras no toda la BD
  /// tiene imagen (fallback de `imageUrl`).
  List<Color> get coverColors => const [Color(0xFF0A0A0A), Color(0xFF3D2A17)];

  /// Dato extra del pie de la tarjeta (ej: "Becas disponibles").
  String get durationLabel => 'Becas disponibles';

  /// Puntos destacados derivados de datos reales (la BD no tiene un
  /// campo "highlights"; se arma con horas y modalidad).
  List<String> get highlights => [
    if (hours > 0) '$hours horas de contenido',
    if (modality == 'live')
      'Sesiones en vivo con instructor'
    else
      'Contenido pregrabado a tu ritmo',
  ];

  /// Precio de oferta VIGENTE, o null si el curso no está en oferta.
  ///
  /// Regla única (detalle, tarjetas, carrito y admin la comparten):
  /// hay oferta cuando `compareAtPrice` existe, es positivo y es MENOR
  /// que el precio general [price] — es decir, un descuento real.
  /// Si vienen invertidos (oferta ≥ general) son datos inconsistentes y
  /// se ignora para no pintar un "descuento" que no existe.
  double? get offerPrice => compareAtPrice != null &&
          compareAtPrice! > 0 &&
          compareAtPrice! < price
      ? compareAtPrice
      : null;

  /// true cuando el curso tiene un descuento real (ver [offerPrice]).
  bool get hasOffer => offerPrice != null;

  /// Precio que paga el cliente: la oferta si la hay, si no el general.
  double get effectivePrice => offerPrice ?? price;
}
