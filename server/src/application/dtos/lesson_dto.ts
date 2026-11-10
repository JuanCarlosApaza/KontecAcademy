import type { NewLessonInput, UpdateLessonInput } from '../../domain/admin.js';
import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/**
 * Tipos de contenido que sabe renderizar el aula:
 *  * recorded/live/drive → se sirven desde sus columnas de URL.
 *  * text                → texto de la lección (content_text).
 *  * file / link         → adjunto (attachment_url + attachment_name).
 */
const CONTENT_TYPES = [
  'recorded',
  'live',
  'drive',
  'text',
  'file',
  'link',
] as const;

/** Campos de contenido que pueden borrarse enviando null. */
const CONTENT_FIELDS = [
  'videoUrl',
  'zoomUrl',
  'driveUrl',
  'contentText',
  'attachmentUrl',
  'attachmentName',
] as const;

/** Body de POST /admin/modules/:id/lessons. */
export type CreateLessonDTO = NewLessonInput;

/** Body de PATCH /admin/lessons/:id. */
export type UpdateLessonDTO = UpdateLessonInput;

function parseContentType(value: unknown): string {
  if (typeof value === 'string' && (CONTENT_TYPES as readonly string[]).includes(value)) {
    return value;
  }
  throw new ValidationError(
    `"contentType" debe ser uno de: ${CONTENT_TYPES.join(' | ')}`,
  );
}

/**
 * Valida el alta de una lección: { title, contentType, videoUrl?,
 * zoomUrl?, driveUrl? }. Lanza [ValidationError] si el título está
 * vacío o el tipo de contenido no está soportado.
 */
export function parseCreateLessonDTO(body: unknown): CreateLessonDTO {
  const record = asRecord(body);

  const title = optionalText(record?.title);
  if (!title) throw new ValidationError('"title" es obligatorio');

  return {
    title,
    contentType: parseContentType(record?.contentType),
    videoUrl: optionalText(record?.videoUrl),
    zoomUrl: optionalText(record?.zoomUrl),
    driveUrl: optionalText(record?.driveUrl),
    contentText: optionalText(record?.contentText),
    attachmentUrl: optionalText(record?.attachmentUrl),
    attachmentName: optionalText(record?.attachmentName),
  };
}

/**
 * Valida la edición de una lección. Al menos un campo debe venir; las
 * URLs pueden borrarse enviando `null` (a diferencia del alta, donde la
 * ausencia simplemente no las rellena).
 */
export function parseUpdateLessonDTO(body: unknown): UpdateLessonDTO {
  const record = asRecord(body);
  const dto: UpdateLessonDTO = {};

  const title = optionalText(record?.title);
  if (title) dto.title = title;

  if (record?.contentType !== undefined) {
    dto.contentType = parseContentType(record.contentType);
  }

  for (const field of CONTENT_FIELDS) {
    const value = record?.[field];
    if (value === undefined) continue;
    dto[field] = optionalText(value);
  }

  if (record?.orderIndex !== undefined) {
    const orderIndex = record.orderIndex;
    if (typeof orderIndex !== 'number' || !Number.isInteger(orderIndex) || orderIndex < 0) {
      throw new ValidationError('"orderIndex" debe ser un entero >= 0');
    }
    dto.orderIndex = orderIndex;
  }

  if (Object.keys(dto).length === 0) {
    throw new ValidationError('Faltan campos de la lección');
  }
  return dto;
}
