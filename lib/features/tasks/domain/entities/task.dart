import 'package:equatable/equatable.dart';

/// Entidad de dominio: el lenguaje del negocio.
/// No conoce JSON, Dio ni Flutter (sin dependencias externas).
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  final String id;
  final String title;
  final bool isDone;

  Task copyWith({String? id, String? title, bool? isDone}) => Task(
        id: id ?? this.id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );

  @override
  List<Object?> get props => [id, title, isDone];
}
