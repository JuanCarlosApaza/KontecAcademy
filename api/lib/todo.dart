/// Entidad del backend: una tarea (todo).
///
/// El frontend (lib/features/tasks/domain/entities/task.dart) representa
/// exactamente lo mismo: `id`, `title`, `completed/isDone`.
class Todo {
  /// Crea una tarea.
  Todo({required this.id, required this.title, this.completed = false});

  /// Construye un [Todo] desde su representación JSON.
  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );

  /// Identificador único.
  final int id;

  /// Texto de la tarea.
  final String title;

  /// Si la tarea está terminada.
  final bool completed;

  /// Serializa el [Todo] a JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
      };
}
