import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Body de POST /admin/courses/:id/modules. */
export interface CreateModuleDTO {
  title: string;
}

/** Body de PATCH /admin/modules/:id (al menos un campo). */
export interface UpdateModuleDTO {
  title?: string;
  orderIndex?: number;
}

/**
 * Valida el alta de un módulo: { title } con título no vacío.
 * Lanza [ValidationError] si falta o viene en blanco.
 */
export function parseCreateModuleDTO(body: unknown): CreateModuleDTO {
  const title = optionalText(asRecord(body)?.title);
  if (!title) throw new ValidationError('"title" es obligatorio');
  return { title };
}

/**
 * Valida la edición de un módulo: { title?, orderIndex? }. Al menos un
 * campo debe venir; `orderIndex` debe ser un entero >= 0.
 */
export function parseUpdateModuleDTO(body: unknown): UpdateModuleDTO {
  const record = asRecord(body);
  const dto: UpdateModuleDTO = {};

  const title = optionalText(record?.title);
  if (title) dto.title = title;

  if (record?.orderIndex !== undefined) {
    const orderIndex = record.orderIndex;
    if (typeof orderIndex !== 'number' || !Number.isInteger(orderIndex) || orderIndex < 0) {
      throw new ValidationError('"orderIndex" debe ser un entero >= 0');
    }
    dto.orderIndex = orderIndex;
  }

  if (dto.title === undefined && dto.orderIndex === undefined) {
    throw new ValidationError('Falta "title" u "orderIndex"');
  }
  return dto;
}
