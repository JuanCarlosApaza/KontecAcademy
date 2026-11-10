import 'package:equatable/equatable.dart';

/// Datos de un módulo del temario (alta o edición, según [moduleId]).
class NewModule extends Equatable {
  const NewModule({
    required this.courseId,
    required this.title,
    this.moduleId,
    this.orderIndex,
  });

  /// Curso al que pertenece (necesario en el alta; en la edición viaja
  /// en la entidad por si el panel quiere recargar el temario).
  final String courseId;

  /// Título del módulo (obligatorio).
  final String title;

  /// null = alta; con id = edición.
  final String? moduleId;

  /// Posición dentro del curso (1-based). Solo al mover.
  final int? orderIndex;

  bool get isEditing => moduleId != null;

  @override
  List<Object?> get props => [courseId, title, moduleId, orderIndex];
}
