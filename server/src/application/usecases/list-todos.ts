import type { Todo, TodoRepository } from '../../domain/todo.js';

/** Caso de uso: listar las tareas (demo de Clean Architecture). */
export class ListTodos {
  constructor(private readonly todos: TodoRepository) {}

  execute(): Promise<Todo[]> {
    return this.todos.findAll();
  }
}
