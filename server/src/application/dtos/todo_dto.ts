import { ValidationError } from '../errors.js';
import { asRecord } from './parse.js';

/** Payload de creación de tarea (POST /todos). */
export interface CreateTodoDTO {
  title: string;
}

/** Valida el body de POST /todos. Lanza [ValidationError]. */
export function parseCreateTodoDTO(body: unknown): CreateTodoDTO {
  const record = asRecord(body);
  const title = typeof record?.title === 'string' ? record.title.trim() : '';

  if (title.length === 0) {
    throw new ValidationError('El campo "title" es obligatorio');
  }
  return { title };
}
