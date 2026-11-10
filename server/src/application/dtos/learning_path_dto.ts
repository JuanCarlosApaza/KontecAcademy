import { PATH_LEVELS } from '../../domain/learning-path.js';
import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Payload de creación de ruta (POST /admin/paths). */
export interface CreatePathDTO {
  title: string;
  /** Si no viene, el caso de uso lo deriva del título. */
  slug?: string;
  description: string;
  coverUrl: string | null;
  modality: 'asynchronous' | 'live';
  durationHours: number | null;
  accessMonths: number;
  /** % de rebaja (0-100) de la ruta sobre su total. */
  discountPercent: number;
  sortOrder: number;
  isPublished: boolean;
}

/** Entero opcional con mínimo; lanza [ValidationError] si es inválido. */
function optionalInt(
  value: unknown,
  field: string,
  { min = 0 }: { min?: number } = {},
): number | null {
  if (value === undefined || value === null || value === '') return null;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < min) {
    throw new ValidationError(
      `El campo "${field}" debe ser un entero mayor o igual a ${min}`,
    );
  }
  return parsed;
}

/** Valida el body de creación/edición de una ruta. */
export function parseCreatePathDTO(body: unknown): CreatePathDTO {
  const record = asRecord(body);
  const title = optionalText(record?.title);

  if (!title) {
    throw new ValidationError('El campo "title" es obligatorio');
  }

  const modality = optionalText(record?.modality) ?? 'asynchronous';
  if (modality !== 'asynchronous' && modality !== 'live') {
    throw new ValidationError('El campo "modality" debe ser asynchronous | live');
  }

  const durationHours = optionalInt(record?.durationHours, 'durationHours');
  const accessMonths =
    optionalInt(record?.accessMonths, 'accessMonths', { min: 1 }) ?? 12;
  const sortOrder = optionalInt(record?.sortOrder, 'sortOrder') ?? 0;

  const discountPercent =
    optionalInt(record?.discountPercent, 'discountPercent') ?? 0;
  if (discountPercent > 100) {
    throw new ValidationError(
      'El campo "discountPercent" debe estar entre 0 y 100',
    );
  }

  return {
    title,
    slug: optionalText(record?.slug) ?? undefined,
    description: optionalText(record?.description) ?? '',
    coverUrl: optionalText(record?.coverUrl),
    modality,
    durationHours,
    accessMonths,
    discountPercent,
    sortOrder,
    isPublished:
      typeof record?.isPublished === 'boolean' ? record.isPublished : true,
  };
}

/** Payload de edición (PATCH /admin/paths/:id): id + mismos campos. */
export interface UpdatePathDTO extends CreatePathDTO {
  id: string;
}

export function parseUpdatePathDTO(
  id: string,
  body: unknown,
): UpdatePathDTO {
  return { id, ...parseCreatePathDTO(body) };
}

/** Entrada válida del selector de cursos. */
export interface SetPathCoursesDTO {
  courses: Array<{
    courseId: string;
    level: string | null;
    sortOrder: number;
  }>;
}

/**
 * Valida el body de PUT /admin/paths/:id/courses.
 * Body: { courses: [{ courseId, level?, sortOrder? }] } (lista vacía = sin cursos).
 */
export function parseSetPathCoursesDTO(body: unknown): SetPathCoursesDTO {
  const record = asRecord(body);
  const raw = record?.courses;

  if (!Array.isArray(raw)) {
    throw new ValidationError('El campo "courses" debe ser una lista');
  }

  const courses = raw.map((item, index) => {
    const entry = asRecord(item);
    const courseId = optionalText(entry?.courseId);
    if (!courseId) {
      throw new ValidationError(
        `courses[${index}].courseId es obligatorio`,
      );
    }

    const level = optionalText(entry?.level);
    if (level !== null && !(PATH_LEVELS as readonly string[]).includes(level)) {
      throw new ValidationError(
        `courses[${index}].level debe ser: ${PATH_LEVELS.join(' | ')}`,
      );
    }

    const sortOrder = optionalInt(entry?.sortOrder, `courses[${index}].sortOrder`);
    return {
      courseId,
      level,
      sortOrder: sortOrder ?? index,
    };
  });

  return { courses };
}
