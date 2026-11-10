import { ValidationError } from '../errors.js';
import { asRecord } from './parse.js';

/** Body de PATCH /lessons/:id/progress. */
export interface LessonProgressDTO {
  completed: boolean;
}

/**
 * Valida el body de PATCH /lessons/:id/progress: { completed: true|false }.
 * Lanza [ValidationError] si falta o no es booleano.
 */
export function parseLessonProgressDTO(body: unknown): LessonProgressDTO {
  const record = asRecord(body);

  if (typeof record?.completed !== 'boolean') {
    throw new ValidationError('"completed" debe ser true o false');
  }
  return { completed: record.completed };
}
