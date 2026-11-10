import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';

/// Modelo de datos: sabe cómo serializar/deserializar.
/// Único lugar del feature que conoce JSON.
class TaskModel extends Equatable {
  const TaskModel({required this.id, required this.title, this.isDone = false});

  final String id;
  final String title;
  final bool isDone;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] is int
        ? (json['id'] as int).toString()
        : json['id'] as String,
    title: json['title'] as String? ?? '',
    isDone: json['completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'title': title, 'completed': isDone};

  Task toEntity() => Task(id: id, title: title, isDone: isDone);

  factory TaskModel.fromEntity(Task task) =>
      TaskModel(id: task.id, title: task.title, isDone: task.isDone);

  @override
  List<Object?> get props => [id, title, isDone];
}
