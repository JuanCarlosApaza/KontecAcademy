import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Payload de alta de rol (POST /admin/roles). */
export interface CreateRoleDTO {
  name: string;
  description: string;
}

/**
 * Nombre de rol en minúsculas: `coordinador`, `admin-externo`, `tutor_1`.
 * Sin espacios ni mayúsculas, para que el nombre sea un identificador
 * estable en la UI, en la BD y en los mensajes de la API.
 */
const ROLE_NAME_PATTERN = /^[a-z][a-z0-9_-]{2,30}$/;

/** Valida el body de POST /admin/roles. Lanza [ValidationError]. */
export function parseCreateRoleDTO(body: unknown): CreateRoleDTO {
  const record = asRecord(body);
  const name = optionalText(record?.name)?.toLowerCase() ?? null;
  const description = optionalText(record?.description) ?? '';

  if (!name || !ROLE_NAME_PATTERN.test(name)) {
    throw new ValidationError(
      'El campo "name" debe ser un nombre de rol en minúsculas (3 a 31 caracteres: letras, números, guiones o guiones bajos)',
    );
  }

  return { name, description };
}

/** Payload de guardado de la matriz (PUT /admin/roles/:id/permissions). */
export interface SaveRolePermissionsDTO {
  /** Códigos concedidos al rol. [] = revocar todos. */
  codes: string[];
}

/**
 * Valida el body de PUT /admin/roles/:id/permissions.
 * Lanza [ValidationError] si `codes` no es un arreglo de strings.
 */
export function parseSaveRolePermissionsDTO(
  body: unknown,
): SaveRolePermissionsDTO {
  const record = asRecord(body);
  const raw = record?.codes;

  if (!Array.isArray(raw)) {
    throw new ValidationError('El campo "codes" debe ser un arreglo');
  }

  const codes: string[] = [];
  for (const value of raw) {
    const code = optionalText(value);
    if (!code) {
      throw new ValidationError('El campo "codes" debe contener solo texto');
    }
    if (!codes.includes(code)) codes.push(code);
  }

  return { codes };
}
