import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Payload de alta de usuario (POST /admin/users). */
export interface CreateAdminUserDTO {
  email: string;
  password: string;
  fullName: string;
  phone: string | null;
  /** 'admin' | 'student' (el backend solo admite esos dos en el alta). */
  role: string;
}

/** Valida el body de POST /admin/users. Lanza [ValidationError]. */
export function parseCreateAdminUserDTO(body: unknown): CreateAdminUserDTO {
  const record = asRecord(body);
  const email = optionalText(record?.email);
  const password =
    typeof record?.password === 'string' && record.password.length >= 6
      ? record.password
      : null;
  const fullName = optionalText(record?.fullName);
  const role = optionalText(record?.role) === 'admin' ? 'admin' : 'student';

  if (!email || !email.includes('@')) {
    throw new ValidationError('El campo "email" no es válido');
  }
  if (!password) {
    throw new ValidationError('La contraseña debe tener al menos 6 caracteres');
  }
  if (!fullName) {
    throw new ValidationError('El campo "fullName" es obligatorio');
  }

  return {
    email,
    password,
    fullName,
    phone: optionalText(record?.phone),
    role,
  };
}

/** Payload de edición de usuario (PATCH /admin/users/:id). */
export interface UpdateAdminUserDTO {
  id: string;
  fullName: string;
  phone: string | null;
  /** Rol único; '' = sin rol. */
  role: string;
  /** false = borrado lógico (los datos se conservan en la BD). */
  isActive: boolean;
}

/** Valida el body de PATCH /admin/users/:id. Lanza [ValidationError]. */
export function parseUpdateAdminUserDTO(
  id: string,
  body: unknown,
): UpdateAdminUserDTO {
  const record = asRecord(body);
  const fullName = optionalText(record?.fullName);
  const roleRaw = record?.role;
  const role =
    typeof roleRaw === 'string'
      ? roleRaw.trim()
      : roleRaw === null || roleRaw === undefined
        ? 'student'
        : '';
  const isActive =
    typeof record?.isActive === 'boolean' ? record.isActive : true;

  if (!fullName) {
    throw new ValidationError('El campo "fullName" es obligatorio');
  }

  return {
    id,
    fullName,
    phone: optionalText(record?.phone),
    role,
    isActive,
  };
}
