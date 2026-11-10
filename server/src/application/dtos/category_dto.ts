import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Payload de creación de categoría (POST /admin/categories). */
export interface CreateCategoryDTO {
  name: string;
  /** Si no viene, el caso de uso lo deriva del nombre. */
  slug?: string;
}

/** Valida el body de POST /admin/categories. Lanza [ValidationError]. */
export function parseCreateCategoryDTO(body: unknown): CreateCategoryDTO {
  const record = asRecord(body);
  const name = optionalText(record?.name);

  if (!name) {
    throw new ValidationError('El campo "name" es obligatorio');
  }
  return { name, slug: optionalText(record?.slug) ?? undefined };
}

/** Payload de renombrado de categoría (PATCH /admin/categories/:id). */
export interface UpdateCategoryDTO extends CreateCategoryDTO {
  id: string;
}

export function parseUpdateCategoryDTO(
  id: string,
  body: unknown,
): UpdateCategoryDTO {
  return { id, ...parseCreateCategoryDTO(body) };
}
