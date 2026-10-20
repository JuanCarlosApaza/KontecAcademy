import 'package:api/todo.dart';

/// Contrato de acceso a datos de las tareas.
///
/// Los `routes/` solo ven esta interfaz: cambiar la implementación
/// (por ejemplo a Postgres) no obliga a tocar los handlers.
abstract interface class TodoRepository {
  /// Devuelve todas las tareas existentes.
  List<Todo> findAll();

  /// Devuelve la tarea con el [id] indicado, o `null` si no existe.
  Todo? findById(int id);

  /// Crea una tarea con el [title] dado y la persiste.
  Todo create(String title);
}

/// Implementación en memoria (inicio de desarrollo).
///
/// Cuando conectes una base de datos (Postgres, SQLite, Firestore...),
/// cambia SOLO esta clase: los route handlers no se enteran.
class InMemoryTodoRepository implements TodoRepository {
  final _todos = <Todo>[];
  int _nextId = 1;

  @override
  List<Todo> findAll() => List.unmodifiable(_todos);

  @override
  Todo? findById(int id) {
    for (final todo in _todos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

  @override
  Todo create(String title) {
    final todo = Todo(id: _nextId++, title: title);
    _todos.add(todo);
    return todo;
  }
}
