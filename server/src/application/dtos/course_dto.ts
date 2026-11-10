import type {
  CourseFilter,
  CourseModality,
  CourseStatus,
} from '../../domain/catalog.js';
import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

const MODALITIES = ['asynchronous', 'live'];
const STATUSES = ['draft', 'upcoming', 'active', 'inactive'];

/** Filtros de GET /courses (?status=&limit=). */
export type ListCoursesDTO = CourseFilter;

export function parseListCoursesDTO(query: unknown): ListCoursesDTO {
  const record = asRecord(query);
  const status =
    typeof record?.status === 'string' ? record.status : undefined;
  const limitRaw = Number(record?.limit);
  const limit =
    Number.isInteger(limitRaw) && limitRaw > 0 ? limitRaw : undefined;
  return { status, limit };
}

/** Payload de creación/edición de curso (POST/PATCH /courses). */
export interface CourseDTO {
  title: string;
  description: string | null;
  imageUrl: string | null;
  categoryId: string | null;
  modality: CourseModality;
  totalHours: number;
  totalWeeks: number | null;
  price: number;
  compareAtPrice: number | null;
  status: CourseStatus;
  professorBio: string | null;
  teachingMethod: string | null;
  targetAudience: string | null;
  certificateInfo: string | null;
  careerOpportunities: string | null;
}

/** Valida el body de POST/PATCH /courses. Lanza [ValidationError]. */
export function parseCourseDTO(body: unknown): CourseDTO {
  const record = asRecord(body);

  const title = typeof record?.title === 'string' ? record.title.trim() : '';
  if (title.length === 0) {
    throw new ValidationError('El campo "title" es obligatorio');
  }

  const modality =
    typeof record?.modality === 'string' ? record.modality : 'asynchronous';
  if (!MODALITIES.includes(modality)) {
    throw new ValidationError('"modality" debe ser "asynchronous" o "live"');
  }

  const status =
    typeof record?.status === 'string' ? record.status : 'active';
  if (!STATUSES.includes(status)) {
    throw new ValidationError(
      '"status" debe ser draft, upcoming, active o inactive',
    );
  }

  const totalHours = Number(record?.totalHours ?? 0);
  const price = Number(record?.price ?? 0);
  const compareAtRaw = record?.compareAtPrice;
  const compareAtPrice =
    compareAtRaw === null || compareAtRaw === undefined || compareAtRaw === ''
      ? null
      : Number(compareAtRaw);
  const totalWeeksRaw = record?.totalWeeks;
  const totalWeeks =
    totalWeeksRaw === null || totalWeeksRaw === undefined || totalWeeksRaw === ''
      ? null
      : Number(totalWeeksRaw);

  const validNumbers =
    Number.isFinite(totalHours) &&
    totalHours >= 0 &&
    Number.isFinite(price) &&
    price >= 0 &&
    (compareAtPrice === null ||
      (Number.isFinite(compareAtPrice) && compareAtPrice >= 0)) &&
    (totalWeeks === null ||
      (Number.isInteger(totalWeeks) && totalWeeks >= 0));
  if (!validNumbers) {
    throw new ValidationError(
      '"totalHours", "price" y "compareAtPrice" deben ser números ≥ 0; "totalWeeks" un entero ≥ 0',
    );
  }

  return {
    title,
    description: optionalText(record?.description),
    imageUrl: optionalText(record?.imageUrl),
    // La existencia de la categoría se verifica en el caso de uso
    // (requiere consultar el repositorio).
    categoryId: optionalText(record?.categoryId),
    modality: modality as CourseModality,
    totalHours,
    totalWeeks,
    price,
    compareAtPrice,
    status: status as CourseStatus,
    professorBio: optionalText(record?.professorBio),
    teachingMethod: optionalText(record?.teachingMethod),
    targetAudience: optionalText(record?.targetAudience),
    certificateInfo: optionalText(record?.certificateInfo),
    careerOpportunities: optionalText(record?.careerOpportunities),
  };
}
