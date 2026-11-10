import 'package:equatable/equatable.dart';

/// Acción que realizó el estudiante durante su sesión
/// (ej: 'view_course', 'add_to_cart', 'purchase').
///
/// Entidad pura del dominio: sin JSON ni Flutter.
class SessionActivity extends Equatable {
  const SessionActivity({required this.action, required this.at, this.detail});

  /// Código corto de la acción (inglés, tipo evento).
  final String action;

  /// Detalle legible (título del curso, email, etc.).
  final String? detail;

  /// Cuándo ocurrió.
  final DateTime at;

  @override
  List<Object?> get props => [action, detail, at];
}
