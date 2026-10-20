import type { Todo, TodoRepository } from '../domain/todo.js';

/**
 * 🔌 DATOS — implementación en memoria (inicio de desarrollo).
 * Cuando conectes la BD de la empresa, sustituye SOLO esta clase.
 * (Equivalente a data/repositories/task_repository_impl.dart del front)
 */
export class InMemoryTodoRepository implements TodoRepository {
  private readonly todos: Todo[] = [];
  private nextId = 1;

  findAll(): Todo[] {
    return [...this.todos];
  }

  findById(id: number): Todo | undefined {
    return this.todos.find((todo) => todo.id === id);
  }

  create(title: string): Todo {
    const todo: Todo = { id: this.nextId++, title, completed: false };
    this.todos.push(todo);
    return todo;
  }
}
