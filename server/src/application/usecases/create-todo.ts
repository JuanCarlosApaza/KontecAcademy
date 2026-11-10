import type { Todo, TodoRepository } from '../../domain/todo.js';
import type { CreateTodoDTO } from '../dtos/todo_dto.js';

/** Caso de uso: crear una tarea. */
export class CreateTodo {
  constructor(private readonly todos: TodoRepository) {}

  execute(dto: CreateTodoDTO): Promise<Todo> {
    return this.todos.create(dto.title);
  }
}
