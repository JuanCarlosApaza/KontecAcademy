import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Acción del admin sobre la inscripción de un estudiante. */
export type EnrollmentAccessAction = 'revoke' | 'restore';

/** Body de PATCH /admin/students/:studentId/enrollments/:courseId. */
export interface EnrollmentAccessDTO {
  action: EnrollmentAccessAction;
}

/** Estado de INSCRIPCIÓN que se persiste para cada acción. */
export const STATUS_OF_ACCESS_ACTION: Record<EnrollmentAccessAction, string> =
  {
    revoke: 'revoked',
    restore: 'approved',
  };

/**
 * Valida el body del endpoint de acceso. Lanza [ValidationError]. Los
 * ids vienen en la ruta; aquí solo se valida la acción.
 */
export function parseEnrollmentAccessDTO(body: unknown): EnrollmentAccessDTO {
  const record = asRecord(body);
  const action = optionalText(record?.action);

  if (action !== 'revoke' && action !== 'restore') {
    throw new ValidationError('"action" debe ser "revoke" o "restore"');
  }
  return { action };
}
